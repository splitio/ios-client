//
//  SplitsUpdateWorker.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class MySegmentsUpdateWorker: UpdateWorker<MySegmentsUpdateNotification> {

    private let synchronizer: Synchronizer
    private let mySegmentsStorage: MySegmentsStorage
    private let decoder: MySegmentsPayloadDecoder
    var changesChecker: MySegmentsChangesChecker
    init(synchronizer: Synchronizer,
         mySegmentsStorage: MySegmentsStorage,
         mySegmentsPayloadDecoder: MySegmentsPayloadDecoder) {
        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.decoder = mySegmentsPayloadDecoder
        self.changesChecker = DefaultMySegmentsChangesChecker()
        super.init(queueName: "MySegmentsUpdateWorker")
    }

    override func process(notification: MySegmentsUpdateNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: MySegmentsUpdateNotification) {
        guard let userKey = getUserKeyFromHash(notification.userKeyHash) else {
            Logger.d("Avoiding process my segments update notification because userKey is null")
            return
        }
        if notification.includesPayload {
            if let segmentList = notification.segmentList {
                // TODO: Check change number logic when implementing my large storage
                let oldSegments = mySegmentsStorage.getAll(forKey: userKey).asArray()
                if changesChecker.mySegmentsHaveChanged(oldSegments: oldSegments,
                                                        newSegments: segmentList) {
                    mySegmentsStorage.set(SegmentChange(segments: segmentList),
                                          forKey: userKey)
                    synchronizer.notifySegmentsUpdated(forKey: userKey)
                }
            } else {
                mySegmentsStorage.clear(forKey: userKey)
            }
        } else {
            synchronizer.forceMySegmentsSync(forKey: userKey)
        }
    }

    private func getUserKeyFromHash(_ hash: String) -> String? {
        let userKeys = mySegmentsStorage.keys
        for userKey in userKeys {
            if hash == decoder.hash(userKey: userKey) {
                return userKey
            }
        }
        return nil
    }
}

class MySegmentsUpdateV2Worker: UpdateWorker<MySegmentsUpdateV2Notification> {

    private let helper: SegmentsUpdateWorkerHelper
    // Visible for testing
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(helper: SegmentsUpdateWorkerHelper) {
        self.helper = helper
        super.init(queueName: "MySegmentsUpdateV2Worker")
    }

    override func process(notification: MySegmentsUpdateV2Notification) throws {
        processQueue.async {
            self.helper.process(SegmentsProcessInfo(notification))
        }
    }
}

class MyLargeSegmentsUpdateWorker: UpdateWorker<MyLargeSegmentsUpdateNotification> {

    private let helper: SegmentsUpdateWorkerHelper
    // Visible for testing
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(helper: SegmentsUpdateWorkerHelper) {
        self.helper = helper
        super.init(queueName: "MyLargeSegmentsUpdateWorker")
    }

    override func process(notification: MyLargeSegmentsUpdateNotification) throws {
        processQueue.async {
            self.helper.process(SegmentsProcessInfo(notification))
        }
    }
}

protocol SegmentsUpdateWorkerHelper {
    func process(_ info: SegmentsProcessInfo)
}

class DefaultSegmentsUpdateWorkerHelper: SegmentsUpdateWorkerHelper {

    private let synchronizer: SegmentsSynchronizerWrapper
    private let mySegmentsStorage: MySegmentsStorage
    private let payloadDecoder: MySegmentsV2PayloadDecoder
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let resource: TelemetryUpdatesFromSseType
    // Visible for testing
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(synchronizer: SegmentsSynchronizerWrapper,
         mySegmentsStorage: MySegmentsStorage,
         payloadDecoder: MySegmentsV2PayloadDecoder,
         telemetryProducer: TelemetryRuntimeProducer?,
         resource: TelemetryUpdatesFromSseType) {

        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.payloadDecoder = payloadDecoder
        self.telemetryProducer = telemetryProducer
        self.resource = resource
    }

    func process(_ info: SegmentsProcessInfo) {

        do {
            switch info.updateStrategy {
            case .unboundedFetchRequest:
                fetchMySegments(delay: info.timeMillis)
            case .boundedFetchRequest:
                if let json = info.data {
                    try handleBounded(encodedKeyMap: json,
                                      compressionUtil: decomProvider.decompressor(for: info.compressionType),
                                      fetchDelay: info.timeMillis)
                }
            case .keyList:
                if let json = info.data, info.segments.count > 0 {
                    try updateSegments(encodedkeyList: json,
                                       segments: info.segments,
                                       compressionUtil: decomProvider.decompressor(for: info.compressionType))
                }
            case .segmentRemoval:
                if info.segments.count > 0 {
                    remove(segments: info.segments)
                }
            case .unknown:
                // should never reach here
                Logger.i("Unknown \(resource)update strategy received")
            }

        } catch {
            Logger.e("Error processing \(resource) notification v2. \(error.localizedDescription)")
            Logger.i("Fall back - unbounded fetch")
            fetchMySegments(delay: info.timeMillis)
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
        synchronizer.forceMyLargeSegmentsSync(forKey: key)
    }
    
    func notifyUpdate(forKey key: String) {
        synchronizer.notifyLargeSegmentsUpdated(forKey: key)
    }
}

struct SegmentsProcessInfo {
    let changeNumber: Int64
    let compressionType: CompressionType
    let updateStrategy: MySegmentUpdateStrategy
    let segments: [String]
    let data: String?
    let hash: Int
    let seed: Int
    let timeMillis: Int64

    init(_ notification: MySegmentsUpdateV2Notification) {
        self.changeNumber = notification.changeNumber ?? -1
        self.compressionType = notification.compressionType
        self.updateStrategy = notification.updateStrategy
        if let segmentName = notification.segmentName {
            self.segments = [segmentName]
        } else {
            self.segments = []
        }
        self.data = notification.data
        self.hash = ServiceConstants.defaultMlsHash
        self.seed = ServiceConstants.defaultMlsSeed
        self.timeMillis = 0
    }

    init(_ notification: MyLargeSegmentsUpdateNotification) {
        self.changeNumber = notification.changeNumber ?? ServiceConstants.defaultMlsChangeNumber
        self.compressionType = notification.compressionType
        self.updateStrategy = notification.updateStrategy
        self.segments = notification.largeSegments ?? []
        self.data = notification.data
        self.hash = notification.hash ?? ServiceConstants.defaultMlsHash
        self.seed = notification.seed ?? ServiceConstants.defaultMlsSeed
        self.timeMillis = notification.timeMillis ?? ServiceConstants.defaultMlsTimeMillis
    }
}


