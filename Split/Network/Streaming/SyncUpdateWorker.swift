//
//  SplitsUpdateWorker.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

///
/// Swift doesn't allow dynamic dispatch
/// when using protocols. So, using this implementation to allow easy UT creation
///
class UpdateWorker<T: NotificationTypeField> {
    fileprivate let processQueue: DispatchQueue

    init(queueName: String) {
        self.processQueue = DispatchQueue(label: queueName)
    }

    func process(notification: T) throws {
        Logger.i("Method has to be overrided by child")
    }
}

class SplitsUpdateWorker: UpdateWorker<SplitsUpdateNotification> {

    private let synchronizer: Synchronizer

    init(synchronizer: Synchronizer) {
        self.synchronizer = synchronizer
        super.init(queueName: "SplitsUpdateWorker")
    }

    override func process(notification: SplitsUpdateNotification) throws {
        processQueue.async {
            self.synchronizer.synchronizeSplits(changeNumber: notification.changeNumber)
        }
    }
}

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
                let oldSegments = mySegmentsStorage.getAll(forKey: userKey)
                if changesChecker.mySegmentsHaveChanged(old: Array(oldSegments), new: segmentList) {
                    mySegmentsStorage.set(segmentList, forKey: userKey)
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

    private let synchronizer: Synchronizer
    private let mySegmentsStorage: MySegmentsStorage
    private let payloadDecoder: MySegmentsV2PayloadDecoder
    private let zlib: CompressionUtil = Zlib()
    private let gzip: CompressionUtil = Gzip()

    init(userKey: String, synchronizer: Synchronizer, mySegmentsStorage: MySegmentsStorage,
         payloadDecoder: MySegmentsV2PayloadDecoder) {

        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.payloadDecoder = payloadDecoder
        super.init(queueName: "MySegmentsUpdateV2Worker")
    }

    override func process(notification: MySegmentsUpdateV2Notification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: MySegmentsUpdateV2Notification) {

        do {
            switch notification.updateStrategy {
            case .unboundedFetchRequest:
                fetchMySegments()
            case .boundedFetchRequest:
                if let json = notification.data {
                    try handleBounded(encodedKeyMap: json,
                                      compressionUtil: decompressor(for: notification.compressionType))
                }
            case .keyList:
                if let json = notification.data, let segmentName = notification.segmentName {
                    try updateSegments(encodedkeyList: json,
                                       segmentName: segmentName,
                                       compressionUtil: decompressor(for: notification.compressionType))
                }
            case .segmentRemoval:
                if let segmentName = notification.segmentName {
                    remove(segment: segmentName)
                }
            case .unknown:
                // should never reach here
                Logger.i("Unknown my segment v2 update strategy received")
            }

        } catch {
            Logger.e("Error processing my segments notification v2. \(error.localizedDescription)")
            Logger.i("Fall back - unbounded fetch")
            fetchMySegments()
        }
    }

    private func fetchMySegments() {
        doForAllUserKeys { userKey in
            fetchMySegments(forKey: userKey)
        }
    }

    private func fetchMySegments(forKey key: String) {
        synchronizer.forceMySegmentsSync(forKey: key)
    }

    private func decompressor(for type: CompressionType) -> CompressionUtil {
        return type == .gzip ? gzip : zlib
    }

    private func remove(segment: String) {
        doForAllUserKeys { userKey in
            remove(segment: segment, forKey: userKey)
        }
    }

    private func remove(segment: String, forKey key: String) {
        var segments = mySegmentsStorage.getAll(forKey: key)
        if segments.remove(segment) != nil {
            mySegmentsStorage.set(Array(segments), forKey: key)
            synchronizer.notifySegmentsUpdated(forKey: key)
        }
    }

    private func updateSegments(encodedkeyList: String, segmentName: String, compressionUtil: CompressionUtil) throws {

        let jsonKeyList = try payloadDecoder.decodeAsString(payload: encodedkeyList, compressionUtil: compressionUtil)
        let keyList = try payloadDecoder.parseKeyList(jsonString: jsonKeyList)

        doForAllUserKeys { userKey in
            let keyHash = payloadDecoder.hashKey(userKey)
            if keyList.added.contains(keyHash) {
                var segments = mySegmentsStorage.getAll(forKey: userKey)
                if !segments.contains(segmentName) {
                    segments.insert(segmentName)
                    mySegmentsStorage.set(Array(segments), forKey: userKey)
                    synchronizer.notifySegmentsUpdated(forKey: userKey)
                }
                return
            }

            if keyList.removed.contains(keyHash) {
                remove(segment: segmentName, forKey: userKey)
            }
        }
    }

    private func handleBounded(encodedKeyMap: String, compressionUtil: CompressionUtil) throws {
        let keyMap = try payloadDecoder.decodeAsBytes(payload: encodedKeyMap, compressionUtil: compressionUtil)

        doForAllUserKeys { userKey in
            let keyHash = payloadDecoder.hashKey(userKey)
            if payloadDecoder.isKeyInBitmap(keyMap: keyMap, hashedKey: keyHash) {
                Logger.d("Executing Unbounded my segment fetch request")
                fetchMySegments(forKey: userKey)
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

class SplitKillWorker: UpdateWorker<SplitKillNotification> {

    private let synchronizer: Synchronizer
    private let splitsStorage: SplitsStorage

    init(synchronizer: Synchronizer, splitsStorage: SplitsStorage) {
        self.synchronizer = synchronizer
        self.splitsStorage = splitsStorage
        super.init(queueName: "SplitKillWorker")
    }

    override func process(notification: SplitKillNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: SplitKillNotification) {

        guard let splitToKill = splitsStorage.get(name: notification.splitName) else {
            return

        }

        if splitToKill.changeNumber ?? -1 >= notification.changeNumber {
            return
        }
        splitToKill.defaultTreatment = notification.defaultTreatment
        splitToKill.changeNumber = notification.changeNumber
        splitToKill.killed = true
        splitsStorage.updateWithoutChecks(split: splitToKill)
        synchronizer.notifySplitKilled()
        synchronizer.synchronizeSplits(changeNumber: notification.changeNumber)
    }
}
