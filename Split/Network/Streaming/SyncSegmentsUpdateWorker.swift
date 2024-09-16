//
//  SplitsUpdateWorker.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class SegmentsUpdateWorker: UpdateWorker<MembershipsUpdateNotification> {

    private let synchronizer: SegmentsSynchronizerWrapper
    private let mySegmentsStorage: MySegmentsStorage
    private let payloadDecoder: SegmentsPayloadDecoder
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let resource: TelemetryUpdatesFromSseType
    // Visible for testing
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(synchronizer: SegmentsSynchronizerWrapper,
         mySegmentsStorage: MySegmentsStorage,
         payloadDecoder: SegmentsPayloadDecoder,
         telemetryProducer: TelemetryRuntimeProducer?,
         resource: TelemetryUpdatesFromSseType) {

        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.payloadDecoder = payloadDecoder
        self.telemetryProducer = telemetryProducer
        self.resource = resource
        super.init(queueName: "split-segments-fetcher")
    }

    override func process(notification: MembershipsUpdateNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    func process(_ info: MembershipsUpdateNotification) {

        do {
            switch info.updateStrategy {
            case .unboundedFetchRequest:
                fetchMySegments(delay: info.timeMillis ?? 0)
            case .boundedFetchRequest:
                if let json = info.data {
                    try handleBounded(encodedKeyMap: json,
                                      compressionUtil: decomProvider.decompressor(for: info.compressionType),
                                      fetchDelay: info.timeMillis ?? 0)
                }
            case .keyList:
                if let json = info.data, info.nnvSegments.count > 0 {
                    try updateSegments(encodedkeyList: json,
                                       segments: info.nnvSegments,
                                       compressionUtil: decomProvider.decompressor(for: info.compressionType))
                }
            case .segmentRemoval:
                if info.nnvSegments.count > 0 {
                    remove(segments: info.nnvSegments)
                }
            case .unknown:
                // should never reach here
                Logger.i("Unknown \(resource)update strategy received")
            }

        } catch {
            Logger.e("Error processing \(resource) notification v2. \(error.localizedDescription)")
            Logger.i("Fall back - unbounded fetch")
            fetchMySegments(delay: info.nnvTimeMillis)
        }
    }

    private func fetchMySegments(delay: Int64) {
        doForAllUserKeys { userKey in
            fetchMySegments(forKey: userKey, delay: delay)
        }
    }

    private func fetchMySegments(forKey key: String, delay: Int64) {
        synchronizer.fetch(byKey: key, delay: delay)
    }

    private func remove(segments: [String]) {
        doForAllUserKeys { userKey in
            remove(segments: segments, forKey: userKey)
        }
    }

    private func remove(segments toRemove: [String], forKey key: String) {
        let segments = mySegmentsStorage.getAll(forKey: key)
        let newSegments = segments.subtracting(toRemove)
        if segments.count > newSegments.count {
            mySegmentsStorage.set(SegmentChange(segments: newSegments.asArray()),
                                  forKey: key)
            synchronizer.notifyUpdate(forKey: key)
            telemetryProducer?.recordUpdatesFromSse(type: resource)
        }
    }

    private func updateSegments(encodedkeyList: String, segments: [String], compressionUtil: CompressionUtil) throws {

        let jsonKeyList = try payloadDecoder.decodeAsString(payload: encodedkeyList, compressionUtil: compressionUtil)
        let keyList = try payloadDecoder.parseKeyList(jsonString: jsonKeyList)

        doForAllUserKeys { userKey in
            let keyHash = payloadDecoder.hashKey(userKey)
            if keyList.added.contains(keyHash) {
                let oldSegments = mySegmentsStorage.getAll(forKey: userKey)
                let newSegments = oldSegments.union(segments)
                if oldSegments.count < newSegments.count {
                    mySegmentsStorage.set(SegmentChange(segments: newSegments.asArray()),
                                          forKey: userKey)
                    synchronizer.notifyUpdate(forKey: userKey)
                    telemetryProducer?.recordUpdatesFromSse(type: .mySegments)
                }
                return
            }

            if keyList.removed.contains(keyHash) {
                remove(segments: segments, forKey: userKey)
            }
        }
    }

    private func handleBounded(encodedKeyMap: String, compressionUtil: CompressionUtil, fetchDelay: Int64) throws {
        let keyMap = try payloadDecoder.decodeAsBytes(payload: encodedKeyMap, compressionUtil: compressionUtil)

        doForAllUserKeys { userKey in
            let keyHash = payloadDecoder.hashKey(userKey)
            if payloadDecoder.isKeyInBitmap(keyMap: keyMap, hashedKey: keyHash) {
                Logger.d("Executing Unbounded my segment fetch request")
                fetchMySegments(forKey: userKey, delay: fetchDelay)
            }
        }
    }

    private func doForAllUserKeys(_ action: (String) -> Void) {
        let userKeys = mySegmentsStorage.keys
        for userKey in userKeys {
            action(userKey)
        }
    }

    private func shouldProcessChangeNumber(_ changeNumber: Int64) -> Bool {
        return changeNumber > mySegmentsStorage.lowerChangeNumber()
    }
}

protocol SegmentsSynchronizerWrapper {
    func fetch(byKey: String, delay: Int64)
    func notifyUpdate(forKey: String)
}

class MySegmentsSynchronizerWrapper: SegmentsSynchronizerWrapper {
    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }

    func fetch(byKey key: String, delay: Int64) {
        // TODO: Add delay parameter to synchronizer
        synchronizer.forceMySegmentsSync(forKey: key)
    }
    
    func notifyUpdate(forKey key: String) {
        synchronizer.notifySegmentsUpdated(forKey: key)
    }
}

class MyLargeSegmentsSynchronizerWrapper: SegmentsSynchronizerWrapper {
    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }

    func fetch(byKey key: String, delay: Int64) {
        // TODO: Add delay parameter to synchronizer
        synchronizer.forceMySegmentsSync(forKey: key)
    }

    func notifyUpdate(forKey key: String) {
        synchronizer.notifyLargeSegmentsUpdated(forKey: key)
    }
}

enum FetchDelayAlgo: Int {
    // 0: NONE
    case none = 0

    // 1: MURMUR3-32
    case murmur332 = 1

    // 2: MURMUR3-64k
    case murmur364 = 2

}

struct FetcherThrottle {
    static func computeDelay(algo: FetchDelayAlgo, userKey: String, seed: Int, timeMillis: Int64) -> Int64 {
        switch algo {
        case .none:
            return 0

        case .murmur332:
            return Int64(Murmur3Hash.hashString(userKey, UInt32(truncatingIfNeeded: seed))) % timeMillis

        case .murmur364:
            return Int64(Murmur64x128.hashKey(userKey, seed: Int32(seed)))
        }
    }
}
