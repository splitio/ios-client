//
//  MySegmentsSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 08-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol MySegmentsSynchronizer {
    func loadMySegmentsFromCache()
    func synchronizeMySegments()
    func forceMySegmentsSync()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func pause()
    func resume()
    func destroy()
}

class DefaultMySegmentsSynchronizer: MySegmentsSynchronizer {

    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let syncWorkerFactory: MySegmentsSyncWorkerFactory
    private let splitConfig: SplitClientConfig
    private let periodicMySegmentsSyncWorker: PeriodicSyncWorker
    private let mySegmentsSyncWorker: RetryableSyncWorker
    private let mySegmentsForcedSyncWorker: RetryableSyncWorker
    private let splitEventsManager: SplitEventsManager
    private var isDestroyed = Atomic(false)

    init(userKey: String,
         splitConfig: SplitClientConfig,
         mySegmentsStorage: ByKeyMySegmentsStorage,
         syncWorkerFactory: MySegmentsSyncWorkerFactory,
         splitEventsManager: SplitEventsManager) {

        self.splitConfig = splitConfig
        self.mySegmentsStorage = mySegmentsStorage
        self.syncWorkerFactory = syncWorkerFactory
        self.periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker(forKey: userKey)
        self.mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(forKey: userKey,
                                                                                          avoidCache: false)
        self.mySegmentsForcedSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(forKey: userKey,
                                                                                                avoidCache: true)
        self.splitEventsManager = splitEventsManager
    }

    func loadMySegmentsFromCache() {
        DispatchQueue.global().async {
            self.mySegmentsStorage.loadLocal()
            self.splitEventsManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
        }
    }

    func synchronizeMySegments() {
        mySegmentsSyncWorker.start()
    }

    func forceMySegmentsSync() {
        mySegmentsForcedSyncWorker.start()
    }

    func startPeriodicFetching() {
        periodicMySegmentsSyncWorker.start()
    }

    func stopPeriodicFetching() {
        periodicMySegmentsSyncWorker.stop()
    }

    func notifiySegmentsUpdated() {
        splitEventsManager.notifyInternalEvent(.mySegmentsUpdated)
    }

    func pause() {
        periodicMySegmentsSyncWorker.pause()
    }

    func resume() {
        periodicMySegmentsSyncWorker.resume()
    }

    func destroy() {
        isDestroyed.set(true)
        mySegmentsSyncWorker.stop()
        periodicMySegmentsSyncWorker.stop()
        mySegmentsForcedSyncWorker.stop()
    }
}
