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
                if shouldProcessChangeNumber(info.uwChangeNumber) {
                    fetchMySegments(info: info)
                }
            case .boundedFetchRequest:
                if let json = info.data {
                    try handleBounded(encodedKeyMap: json,
                                      compressionUtil: decomProvider.decompressor(for: info.compressionType ?? CompressionType.none),
                                      info: info)
                }
            case .keyList:
                if let json = info.data, info.uwSegments.count > 0 {
                    try updateSegments(encodedkeyList: json,
                                       segments: info.uwSegments,
                                       compressionUtil: decomProvider.decompressor(for: info.compressionType ?? CompressionType.none))
                }
            case .segmentRemoval:
                if info.uwSegments.count > 0 {
                    remove(segments: info.uwSegments)
                }
            case .unknown:
                // should never reach here
                Logger.i("Unknown \(resource)update strategy received")
            }

        } catch {
            Logger.e("Error processing \(resource) notification. \(error.localizedDescription)")
            Logger.i("Fall back - unbounded fetch")
            fetchMySegments(info: info)
        }
    }

    private func fetchMySegments(info: MembershipsUpdateNotification) {
        doForAllUserKeys { userKey in
            if info.uwChangeNumber == ServiceConstants.defaultSegmentsChangeNumber ||
                info.uwChangeNumber > mySegmentsStorage.changeNumber(forKey: userKey) ?? -1 {
                fetchMySegments(forKey: userKey, info: info)
            }
        }
    }

    private func fetchMySegments(forKey key: String, info: MembershipsUpdateNotification) {
        let delay = FetcherThrottle.computeDelay(algo: info.uwHash,
                                                 userKey: key,
                                                 seed: info.uwSeed,
                                                 timeMillis: info.uwTimeMillis)

        let changeNumber = SegmentsChangeNumber(
            msChangeNumber: info.type == .mySegmentsUpdate ? info.uwChangeNumber : ServiceConstants.defaultSegmentsChangeNumber,
            mlsChangeNumber: info.type == .myLargeSegmentsUpdate ? info.uwChangeNumber : ServiceConstants.defaultSegmentsChangeNumber
        )
        synchronizer.fetch(byKey: key,
                           changeNumbers: changeNumber,
                           delay: delay)
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
            synchronizer.notifyUpdate(forKey: key, metadata: EventMetadata(type: .SEGMENTS_UPDATED, data: toRemove.joined(separator: ",")))
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
                    synchronizer.notifyUpdate(forKey: userKey, metadata: EventMetadata(type: .SEGMENTS_UPDATED, data: segments.joined(separator: ",")))
                    telemetryProducer?.recordUpdatesFromSse(type: .mySegments)
                }
                return
            }

            if keyList.removed.contains(keyHash) {
                remove(segments: segments, forKey: userKey)
            }
        }
    }

    private func handleBounded(encodedKeyMap: String,
                               compressionUtil: CompressionUtil,
                               info: MembershipsUpdateNotification) throws {
        let keyMap = try payloadDecoder.decodeAsBytes(payload: encodedKeyMap, compressionUtil: compressionUtil)

        doForAllUserKeys { userKey in
            let keyHash = payloadDecoder.hashKey(userKey)
            if payloadDecoder.isKeyInBitmap(keyMap: keyMap, hashedKey: keyHash) {
                Logger.d("Executing Unbounded my segment fetch request")
                fetchMySegments(forKey: userKey, info: info)
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
        if changeNumber == -1 {
            return true
        }
        return changeNumber > mySegmentsStorage.lowerChangeNumber()
    }
}

protocol SegmentsSynchronizerWrapper {
    func fetch(byKey: String, changeNumbers: SegmentsChangeNumber, delay: Int64)
    func notifyUpdate(forKey: String, metadata: EventMetadata?)
}

class MySegmentsSynchronizerWrapper: SegmentsSynchronizerWrapper {
    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }

    func fetch(byKey key: String, changeNumbers: SegmentsChangeNumber, delay: Int64) {
        synchronizer.forceMySegmentsSync(forKey: key, changeNumbers: changeNumbers, delay: delay)
    }

    func notifyUpdate(forKey key: String, metadata: EventMetadata? = nil) {
        synchronizer.notifySegmentsUpdated(forKey: key, metadata: metadata)
    }
}

class MyLargeSegmentsSynchronizerWrapper: SegmentsSynchronizerWrapper {
    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
    }

    func fetch(byKey key: String, changeNumbers: SegmentsChangeNumber, delay: Int64) {
        synchronizer.forceMySegmentsSync(forKey: key, changeNumbers: changeNumbers, delay: delay)
    }

    func notifyUpdate(forKey key: String, metadata: EventMetadata? = nil) {
        synchronizer.notifyLargeSegmentsUpdated(forKey: key, metadata: metadata)
    }
}

enum FetchDelayAlgo: Decodable {
    // 0: NONE
    case none

    // 1: MURMUR3-32
    case murmur332

    // 2: MURMUR3-64k
    case murmur364

        init(from decoder: Decoder) throws {
            let intValue = try? decoder.singleValueContainer().decode(Int.self)
            self = FetchDelayAlgo.enumFromInt(intValue ?? 0)
        }

    static func enumFromInt(_ intValue: Int) -> FetchDelayAlgo {
            switch intValue {
            case 0:
                return FetchDelayAlgo.none
            case 1:
                return FetchDelayAlgo.murmur332
            case 2:
                return FetchDelayAlgo.murmur364
            default:
                return FetchDelayAlgo.none
            }
    }
}

struct FetcherThrottle {
    static func computeDelay(algo: FetchDelayAlgo, userKey: String, seed: Int, timeMillis: Int64) -> Int64 {
        if timeMillis == 0 {
            return 0
        }

        switch algo {
        case .none:
            return 0

        case .murmur332:
            return Int64(Murmur3Hash.hashString(userKey, UInt32(truncatingIfNeeded: seed))) % timeMillis

        case .murmur364:
            return Int64(Murmur64x128.hashKey(userKey, seed: Int32(seed))) % timeMillis
        }
    }
}
