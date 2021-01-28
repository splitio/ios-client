//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol ImpressionLogger {
    func pushImpression(impression: Impression)
}

protocol Synchronizer: ImpressionLogger {
    func syncAll()
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startPeriodicRecording()
    func stopPeriodicRecording()
    func pushEvent(event: EventDTO)
    func pause()
    func resume()
    func flush()
    func destroy()
}

struct SplitStorageContainer {
    let fileStorage: FileStorageProtocol
    let splitsStorage: SplitsStorage
    let mySegmentsStorage: MySegmentsStorage
    let impressionsStorage: PersistentImpressionsStorage
}

class DefaultSynchronizer: Synchronizer {

    private let splitApiFacade: SplitApiFacade
    private let splitStorageContainer: SplitStorageContainer
    private let syncWorkerFactory: SyncWorkerFactory
    private let syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
    private let splitConfig: SplitClientConfig
    private let impressionsSyncHelper: ImpressionsRecorderSyncHelper

    private let periodicSplitsSyncWorker: PeriodicSyncWorker
    private let periodicMySegmentsSyncWorker: PeriodicSyncWorker
    private let splitsSyncWorker: RetryableSyncWorker
    private let mySegmentsSyncWorker: RetryableSyncWorker
    private let periodicImpressionsRecorderWoker: PeriodicRecorderWorker
    private let flusherImpressionsRecorderWorker: RecorderWorker
    private let trackManager: TrackManager

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
        = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>()) {
        self.splitConfig = splitConfig
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog
        self.impressionsSyncHelper = impressionsSyncHelper


        periodicSplitsSyncWorker = syncWorkerFactory.createPeriodicSplitsSyncWorker()
        periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker()
        splitsSyncWorker = syncWorkerFactory.createRetryableSplitsSyncWorker()
        mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker()
        flusherImpressionsRecorderWorker = syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        periodicImpressionsRecorderWoker = syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        trackManager = splitApiFacade.trackManager
    }

    func syncAll() {
        splitsSyncWorker.start()
        mySegmentsSyncWorker.start()
    }

    func synchronizeSplits() {
        splitsSyncWorker.start()
    }

    func synchronizeSplits(changeNumber: Int64) {

        if changeNumber <= splitStorageContainer.splitsStorage.changeNumber {
            return
        }

        if syncTaskByChangeNumberCatalog.value(forKey: changeNumber) == nil {
            let reconnectBackoff = DefaultReconnectBackoffCounter(backoffBase: splitConfig.generalRetryBackoffBase)
            var worker = syncWorkerFactory.createRetryableSplitsUpdateWorker(changeNumber: changeNumber,
                                                                             reconnectBackoffCounter: reconnectBackoff)
            syncTaskByChangeNumberCatalog.setValue(worker, forKey: changeNumber)
            worker.start()
            worker.completion = {[weak self] _ in
                if let self = self {
                    self.syncTaskByChangeNumberCatalog.removeValue(forKey: changeNumber)
                }
            }
        }
    }

    func synchronizeMySegments() {
        mySegmentsSyncWorker.start()
    }

    func startPeriodicFetching() {
        periodicSplitsSyncWorker.start()
        periodicMySegmentsSyncWorker.start()
    }

    func stopPeriodicFetching() {
        periodicSplitsSyncWorker.stop()
        periodicMySegmentsSyncWorker.stop()
    }

    func startPeriodicRecording() {
        periodicImpressionsRecorderWoker.start()
        trackManager.start()
    }

    func stopPeriodicRecording() {
        periodicImpressionsRecorderWoker.stop()
        trackManager.stop()
    }

    func pushEvent(event: EventDTO) {
        trackManager.appendEvent(event: event)
    }

    func pushImpression(impression: Impression) {
        splitStorageContainer.impressionsStorage.push(impression: impression)
    }

    func pause() {
        periodicSplitsSyncWorker.pause()
        periodicMySegmentsSyncWorker.pause()
    }

    func resume() {
        periodicSplitsSyncWorker.resume()
        periodicMySegmentsSyncWorker.resume()
    }

    func flush() {
        flusherImpressionsRecorderWorker.flush()
        trackManager.flush()
    }

    func destroy() {
        splitsSyncWorker.stop()
        mySegmentsSyncWorker.stop()
        periodicSplitsSyncWorker.stop()
        periodicMySegmentsSyncWorker.stop()
        periodicSplitsSyncWorker.destroy()
        periodicMySegmentsSyncWorker.destroy()
        let updateTasks = syncTaskByChangeNumberCatalog.takeAll()
        for task in updateTasks.values {
            task.stop()
        }
    }
}
