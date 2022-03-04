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
        fatalError()
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
    private let mySegmentsStorage: OneKeyMySegmentsStorage
    var changesChecker: MySegmentsChangesChecker
    init(synchronizer: Synchronizer, mySegmentsStorage: OneKeyMySegmentsStorage) {
        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.changesChecker = DefaultMySegmentsChangesChecker()
        super.init(queueName: "MySegmentsUpdateWorker")
    }

    override func process(notification: MySegmentsUpdateNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: MySegmentsUpdateNotification) {
        if notification.includesPayload {
            if let segmentList = notification.segmentList {
                let oldSegments = mySegmentsStorage.getAll()
                if changesChecker.mySegmentsHaveChanged(old: Array(oldSegments), new: segmentList) {
                    mySegmentsStorage.set(segmentList)
                    synchronizer.notifiySegmentsUpdated()
                }
            } else {
                mySegmentsStorage.clear()
            }
        } else {
            synchronizer.forceMySegmentsSync()
        }
    }
}

class MySegmentsUpdateV2Worker: UpdateWorker<MySegmentsUpdateV2Notification> {

    private let synchronizer: Synchronizer
    private let mySegmentsStorage: OneKeyMySegmentsStorage
    private let payloadDecoder: MySegmentsV2PayloadDecoder
    private let zlib: CompressionUtil = Zlib()
    private let gzip: CompressionUtil = Gzip()
    private let keyHash: UInt64

    init(userKey: String, synchronizer: Synchronizer, mySegmentsStorage: OneKeyMySegmentsStorage,
         payloadDecoder: MySegmentsV2PayloadDecoder) {
        self.synchronizer = synchronizer
        self.mySegmentsStorage = mySegmentsStorage
        self.payloadDecoder = payloadDecoder
        self.keyHash = payloadDecoder.hashKey(userKey)
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
        synchronizer.forceMySegmentsSync()
    }

    private func decompressor(for type: CompressionType) -> CompressionUtil {
        return type == .gzip ? gzip : zlib
    }
    private func remove(segment: String) {
        var segments = mySegmentsStorage.getAll()
        if segments.remove(segment) != nil {
            mySegmentsStorage.set(Array(segments))
            synchronizer.notifiySegmentsUpdated()
        }
    }

    private func updateSegments(encodedkeyList: String, segmentName: String, compressionUtil: CompressionUtil) throws {

        let jsonKeyList = try payloadDecoder.decodeAsString(payload: encodedkeyList, compressionUtil: compressionUtil)
        let keyList = try payloadDecoder.parseKeyList(jsonString: jsonKeyList)

        if keyList.added.contains(keyHash) {
            var segments = mySegmentsStorage.getAll()
            if !segments.contains(segmentName) {
                segments.insert(segmentName)
                mySegmentsStorage.set(Array(segments))
                synchronizer.notifiySegmentsUpdated()
            }
            return
        }

        if keyList.removed.contains(keyHash) {
            remove(segment: segmentName)
            return
        }
    }

    private func handleBounded(encodedKeyMap: String, compressionUtil: CompressionUtil) throws {
        let keyMap = try payloadDecoder.decodeAsBytes(payload: encodedKeyMap, compressionUtil: compressionUtil)
        if payloadDecoder.isKeyInBitmap(keyMap: keyMap, hashedKey: keyHash) {
            Logger.d("Executing Unbounded my segment fetch request")
            fetchMySegments()
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
