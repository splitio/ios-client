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
    func forceMySegmentsSync(changeNumbers: SegmentsChangeNumber, delay: Int64)
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func pause()
    func resume()
    func destroy()
}

class DefaultMySegmentsSynchronizer: MySegmentsSynchronizer {
    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let myLargeSegmentsStorage: ByKeyMySegmentsStorage
    private let syncWorkerFactory: MySegmentsSyncWorkerFactory
    private let splitConfig: SplitClientConfig
    private var periodicMySegmentsSyncWorker: PeriodicSyncWorker?
    private let mySegmentsSyncWorker: RetryableSyncWorker
    private var mySegmentsForcedSyncWorker: RetryableSyncWorker?
    private var syncTaskByCnCatalog: ConcurrentDictionary<String, RetryableSyncWorker>?

    private let eventsManager: SplitEventsManager
    private var isDestroyed = Atomic(false)
    private let userKey: String
    private var timerManager: TimersManager?
    private var syncChangeNumbers: Atomic<SegmentsChangeNumber>?

    init(
        userKey: String,
        splitConfig: SplitClientConfig,
        mySegmentsStorage: ByKeyMySegmentsStorage,
        myLargeSegmentsStorage: ByKeyMySegmentsStorage,
        syncWorkerFactory: MySegmentsSyncWorkerFactory,
        eventsManager: SplitEventsManager,
        timerManager: TimersManager?) {
        self.userKey = userKey
        self.splitConfig = splitConfig
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.syncWorkerFactory = syncWorkerFactory
        self.eventsManager = eventsManager
        self.mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(
            forKey: userKey,
            avoidCache: false,
            eventsManager: eventsManager,
            changeNumbers: nil)

        // If no single sync mode is enabled, create periodic and forced worker (polling and streaming)
        if splitConfig.syncEnabled {
            self.periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker(
                forKey: userKey,
                eventsManager: eventsManager)
            self.mySegmentsForcedSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(
                forKey: userKey,
                avoidCache: true,
                eventsManager: eventsManager,
                changeNumbers: nil)
            self.syncTaskByCnCatalog = ConcurrentDictionary<String, RetryableSyncWorker>()
            self.timerManager = timerManager
            self.syncChangeNumbers = Atomic(SegmentsChangeNumber(
                msChangeNumber: ServiceConstants.defaultSegmentsChangeNumber,
                mlsChangeNumber: ServiceConstants.defaultSegmentsChangeNumber))
        }
    }

    func loadMySegmentsFromCache() {
        if isDestroyed.value {
            return
        }
        DispatchQueue.general.async { [weak self] in
            guard let self = self else { return }
            self.mySegmentsStorage.loadLocal()
            self.eventsManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
            self.myLargeSegmentsStorage.loadLocal()
            self.eventsManager.notifyInternalEvent(.myLargeSegmentsLoadedFromCache)
            TimeChecker.logInterval("Time until my segments loaded from cache")
            let msChangeNumber = self.mySegmentsStorage.changeNumber
            let mlsChangeNumber = self.myLargeSegmentsStorage.changeNumber
            self.syncChangeNumbers?.set(SegmentsChangeNumber(
                msChangeNumber: msChangeNumber,
                mlsChangeNumber: mlsChangeNumber))
        }
    }

    func synchronizeMySegments() {
        if isDestroyed.value {
            return
        }
        mySegmentsSyncWorker.start()
    }

    func forceMySegmentsSync(changeNumbers: SegmentsChangeNumber, delay: Int64) {
        if isDestroyed.value {
            return
        }
        delayedSync(changeNumbers: changeNumbers, delay: delay)
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

    private func delayedSync(changeNumbers: SegmentsChangeNumber, delay: Int64) {
        if isDestroyed.value || !splitConfig.syncEnabled {
            return
        }

        if changeNumbers.msChangeNumber != ServiceConstants.defaultSegmentsChangeNumber,
           changeNumbers.mlsChangeNumber != ServiceConstants.defaultSegmentsChangeNumber,
           changeNumbers.msChangeNumber <= mySegmentsStorage.changeNumber,
           changeNumbers.mlsChangeNumber <= myLargeSegmentsStorage.changeNumber {
            return
        }

        syncChangeNumbers?.mutate {
            if $0.msChangeNumber <= changeNumbers.msChangeNumber,
               changeNumbers.mlsChangeNumber <= changeNumbers.mlsChangeNumber {}
        }

        if timerManager?.isScheduled(timer: .syncSegments) ?? false {
            return
        }

        if syncTaskByCnCatalog?.count ?? 0 > 0 {
            return
        }

        if delay == 0 {
            executeSync()
        } else {
            _ = timerManager?.addNoReplace(timer: .syncSegments, task: createSyncTask(time: delay))
        }
    }

    private func createSyncTask(time: Int64) -> CancellableTask {
        return DefaultTask(delay: time / 1000) { [weak self] in
            guard let self = self else { return }
            self.executeSync()
        }
    }

    private func executeSync() {
        guard let taskCatalog = syncTaskByCnCatalog else {
            return
        }
        guard let changeNumbers = syncChangeNumbers?.value else {
            return
        }
        let cnKey = changeNumbers.asString()
        if taskCatalog.value(forKey: cnKey) == nil {
            var worker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(
                forKey: userKey,
                avoidCache: true,
                eventsManager: eventsManager,
                changeNumbers: changeNumbers)
            taskCatalog.setValue(worker, forKey: cnKey)
            worker.start()
            worker.completion = { success in
                if success {
                    taskCatalog.removeValue(forKey: cnKey)
                }
            }
        }
    }
}
