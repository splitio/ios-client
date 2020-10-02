//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer {
    func syncAll()
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startPeriodicRecording()
    func stopPeriodicRecording()
    func pushEvent(event: EventDTO)
    func pushImpression(impression: Impression)
    func flush()
    func destroy()
}

struct SplitStorageContainer {
    let fileStorage: FileStorageProtocol
    let splitsCache: SplitCacheProtocol
    let mySegmentsCache: MySegmentsCacheProtocol
}

class DefaultSynchronizer: Synchronizer {

    private let splitApiFacade: SplitApiFacade
    private let splitStorageContainer: SplitStorageContainer
    private let syncWorkerFactory: SyncWorkerFactory
    private let syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>

    init(splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory = DefaultSyncWorkerFactory(),
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
        = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>()) {
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog
    }

    func syncAll() {
        splitApiFacade.splitsSyncWorker.start()
        splitApiFacade.mySegmentsSyncWorker.start()
    }

    func synchronizeSplits() {
        splitApiFacade.splitsSyncWorker.start()
    }

    func synchronizeSplits(changeNumber: Int64) {

        if changeNumber <= splitStorageContainer.splitsCache.getChangeNumber() {
            return
        }

        if syncTaskByChangeNumberCatalog.value(forKey: changeNumber) == nil {
            // TODO: Replace constant 1 with config value. (Integration PR)
            let reconnectBackoff = DefaultReconnectBackoffCounter(backoffBase: 1)
            var worker = syncWorkerFactory.createRetryableSplitsUpdateWorker(
                splitChangeFetcher: splitApiFacade.splitsFetcher,
                splitCache: splitStorageContainer.splitsCache,
                changeNumber: changeNumber,
                reconnectBackoffCounter: reconnectBackoff)
            syncTaskByChangeNumberCatalog.setValue(worker, forKey: changeNumber)
            worker.start()
            worker.completion = {[weak self] success in
                if let self = self {
                    self.syncTaskByChangeNumberCatalog.removeValue(forKey: changeNumber)
                }
            }
        }
    }

    func synchronizeMySegments() {
        splitApiFacade.mySegmentsSyncWorker.start()
    }

    func startPeriodicFetching() {
        splitApiFacade.periodicSplitsSyncWorker.start()
        splitApiFacade.periodicMySegmentsSyncWorker.start()
    }

    func stopPeriodicFetching() {
        splitApiFacade.periodicSplitsSyncWorker.stop()
        splitApiFacade.periodicMySegmentsSyncWorker.stop()
    }

    func startPeriodicRecording() {
        splitApiFacade.impressionsManager.start()
        splitApiFacade.trackManager.start()
    }

    func stopPeriodicRecording() {
        splitApiFacade.impressionsManager.stop()
        splitApiFacade.trackManager.stop()
    }

    func pushEvent(event: EventDTO) {
        splitApiFacade.trackManager.appendEvent(event: event)
    }

    func pushImpression(impression: Impression) {
        if let splitName = impression.feature {
            splitApiFacade.impressionsManager.appendImpression(impression: impression, splitName: splitName)
        }
    }

    func flush() {
        splitApiFacade.impressionsManager.flush()
        splitApiFacade.trackManager.flush()
    }

    func destroy() {
        splitApiFacade.splitsSyncWorker.stop()
        splitApiFacade.mySegmentsSyncWorker.stop()
        splitApiFacade.periodicSplitsSyncWorker.stop()
        splitApiFacade.periodicMySegmentsSyncWorker.stop()
        let updateTasks = syncTaskByChangeNumberCatalog.takeAll()
        for task in updateTasks.values {
            task.stop()
        }
    }
}
