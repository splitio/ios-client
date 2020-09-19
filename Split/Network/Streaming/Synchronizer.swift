//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer {
    func runInitialSynchronization()
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

struct SplitApiFacade {
    let splitsFetcher: SplitChangeFetcher
    let impressionsManager: ImpressionsManager
    let trackManager: TrackManager
    let splitsSyncWorker: RetryableSyncWorker
    let mySegmentsSyncWorker: RetryableSyncWorker
    let periodicSplitsSyncWorker: PeriodicSyncWorker
    let periodicMySegmentsSyncWorker: PeriodicSyncWorker
}

struct SplitStorageContainer {
    let splitsCache: SplitCacheProtocol
    let mySegmentsCache: MySegmentsCacheProtocol
}

class DefaultSynchronizer: Synchronizer {

    private let splitApiFacade: SplitApiFacade
    private let splitStorageContainer: SplitStorageContainer
    private let syncTasksByChangeNumber = SyncDictionarySingleWrapper<Int64, RetryableSplitsUpdateWorker>()

    init(splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer) {
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
    }

    func runInitialSynchronization() {
        splitApiFacade.splitsSyncWorker.start()
        splitApiFacade.mySegmentsSyncWorker.start()
    }

    func synchronizeSplits() {
        splitApiFacade.splitsSyncWorker.start()
    }

    func synchronizeSplits(changeNumber: Int64) {
        if syncTasksByChangeNumber.value(forKey: changeNumber) != nil {
            let reconnectBackoff = DefaultReconnectBackoffCounter(backoffBase: 1)
            let worker = RetryableSplitsUpdateWorker(splitChangeFetcher: splitApiFacade.splitsFetcher,
                                                     splitCache: splitStorageContainer.splitsCache,
                                                     changeNumber: changeNumber,
                                                     reconnectBackoffCounter: reconnectBackoff)
            syncTasksByChangeNumber.setValue(worker, forKey: changeNumber)
            worker.completion = {[weak self] success in
                if let self = self {
                    self.syncTasksByChangeNumber.removeValue(forKey: changeNumber)
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
        let updateTasks = syncTasksByChangeNumber.takeAll()
        for task in updateTasks.values {
            task.stop()
        }
    }
}
