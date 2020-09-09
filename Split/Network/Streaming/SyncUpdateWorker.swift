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
    private let mySegmentsCache: MySegmentsCacheProtocol
    init(synchronizer: Synchronizer, mySegmentsCache: MySegmentsCacheProtocol) {
        self.synchronizer = synchronizer
        self.mySegmentsCache = mySegmentsCache
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
                mySegmentsCache.setSegments(segmentList)
            } else {
                mySegmentsCache.clear()
            }
        } else {
            synchronizer.synchronizeMySegments()
        }
    }
}

class SplitKillWorker: UpdateWorker<SplitKillNotification> {

    private let synchronizer: Synchronizer
    private let splitCache: SplitCacheProtocol

    init(synchronizer: Synchronizer, splitCache: SplitCacheProtocol) {
        self.synchronizer = synchronizer
        self.splitCache = splitCache
        super.init(queueName: "SplitKillWorker")
    }

    override func process(notification: SplitKillNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: SplitKillNotification) {
        splitCache.kill(splitName: notification.splitName,
                        defaultTreatment: notification.defaultTreatment,
                        changeNumber: notification.changeNumber)
        synchronizer.synchronizeSplits(changeNumber: notification.changeNumber)
    }
}
