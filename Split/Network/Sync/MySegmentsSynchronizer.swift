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
    private var periodicMySegmentsSyncWorker: PeriodicSyncWorker?
    private let mySegmentsSyncWorker: RetryableSyncWorker
    private var mySegmentsForcedSyncWorker: RetryableSyncWorker?
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
        self.splitEventsManager = splitEventsManager
        self.mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(
            forKey: userKey,
            avoidCache: false,
            eventsManager: splitEventsManager)
        // If no single sync mode is enabled, create periodic and forced worker (polling and streaming)
        if splitConfig.syncEnabled {
            self.periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker(
                forKey: userKey,
                eventsManager: splitEventsManager)
            self.mySegmentsForcedSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(
                forKey: userKey,
                avoidCache: true,
                eventsManager: splitEventsManager)
        }
    }

    func loadMySegmentsFromCache() {
        if isDestroyed.value {
            return
        }
        DispatchQueue.general.async {
            self.mySegmentsStorage.loadLocal()
            self.splitEventsManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
            TimeChecker.logInterval("Time until my segments loaded from cache")
        }
    }

    func synchronizeMySegments() {
        if isDestroyed.value {
            return
        }
        mySegmentsSyncWorker.start()
    }

    func forceMySegmentsSync() {
        if isDestroyed.value {
            return
        }
        mySegmentsForcedSyncWorker?.start()
    }

    func startPeriodicFetching() {
        if isDestroyed.value {
            return
        }
        periodicMySegmentsSyncWorker?.start()
    }

    func stopPeriodicFetching() {
        if isDestroyed.value {
            return
        }
        periodicMySegmentsSyncWorker?.stop()
    }

    func notifiySegmentsUpdated() {
        splitEventsManager.notifyInternalEvent(.mySegmentsUpdated)
    }

    func pause() {
        periodicMySegmentsSyncWorker?.pause()
    }

    func resume() {
        if isDestroyed.value {
            return
        }
        periodicMySegmentsSyncWorker?.resume()
    }

    func destroy() {
        isDestroyed.set(true)
        mySegmentsSyncWorker.stop()
        periodicMySegmentsSyncWorker?.stop()
        mySegmentsForcedSyncWorker?.stop()
    }
}
