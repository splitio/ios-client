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
    func loadAndSynchronizeSplits()
    func loadMySegmentsFromCache()
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
    let splitDatabase: SplitDatabase
    let fileStorage: FileStorageProtocol
    let splitsStorage: SplitsStorage
    let persistentSplitsStorage: PersistentSplitsStorage
    let mySegmentsStorage: MySegmentsStorage
    let impressionsStorage: PersistentImpressionsStorage
    let eventsStorage: PersistentEventsStorage
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
    private let periodicEventsRecorderWoker: PeriodicRecorderWorker
    private let flusherEventsRecorderWorker: RecorderWorker
    private let eventsSyncHelper: EventsRecorderSyncHelper
    private let splitsFilterQueryString: String

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         eventsSyncHelper: EventsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
        = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String) {
        self.splitConfig = splitConfig
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog
        self.periodicSplitsSyncWorker = syncWorkerFactory.createPeriodicSplitsSyncWorker()
        self.periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker()
        self.splitsSyncWorker = syncWorkerFactory.createRetryableSplitsSyncWorker()
        self.mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker()
        self.flusherImpressionsRecorderWorker =
            syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.periodicImpressionsRecorderWoker =
            syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.flusherEventsRecorderWorker = syncWorkerFactory.createEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.periodicEventsRecorderWoker =
            syncWorkerFactory.createPeriodicEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.impressionsSyncHelper = impressionsSyncHelper
        self.eventsSyncHelper = eventsSyncHelper
        self.splitsFilterQueryString = splitsFilterQueryString
    }

    func loadAndSynchronizeSplits() {
        DispatchQueue.global().async {
            self.filterSplitsInCache()
            self.splitStorageContainer.splitsStorage.loadLocal()
            self.synchronizeSplits()
        }

    }

    func loadMySegmentsFromCache() {
        DispatchQueue.global().async {
            self.splitStorageContainer.mySegmentsStorage.loadLocal()
        }
    }

    func syncAll() {
        synchronizeSplits()
        synchronizeMySegments()
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
        periodicEventsRecorderWoker.start()
    }

    func stopPeriodicRecording() {
        periodicImpressionsRecorderWoker.stop()
        periodicEventsRecorderWoker.stop()
    }

    func pushEvent(event: EventDTO) {
        if eventsSyncHelper.pushAndCheckFlush(event) {
            flusherEventsRecorderWorker.flush()
        }
    }

    func pushImpression(impression: Impression) {
        if impressionsSyncHelper.pushAndCheckFlush(impression) {
            flusherImpressionsRecorderWorker.flush()
        }
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
        flusherEventsRecorderWorker.flush()
    }

    func destroy() {
        splitsSyncWorker.stop()
        mySegmentsSyncWorker.stop()
        periodicSplitsSyncWorker.stop()
        periodicMySegmentsSyncWorker.stop()
        periodicSplitsSyncWorker.destroy()
        periodicMySegmentsSyncWorker.destroy()
        periodicImpressionsRecorderWoker.destroy()
        periodicEventsRecorderWoker.destroy()
        let updateTasks = syncTaskByChangeNumberCatalog.takeAll()
        for task in updateTasks.values {
            task.stop()
        }
    }

    private func filterSplitsInCache() {
        let splitsStorage = splitStorageContainer.persistentSplitsStorage
        let currentSplitsQueryString = splitsFilterQueryString
        if currentSplitsQueryString == splitsStorage.getFilterQueryString() {
            return
        }

        let filters = splitConfig.sync.filters
        let namesToKeep = Set(filters.filter { $0.type == .byName }.flatMap { $0.values })
        let prefixesToKeep = Set(filters.filter { $0.type == .byPrefix }.flatMap { $0.values })

        let splitsInCache = splitsStorage.getAll()
        var toDelete = [String]()

        for split in splitsInCache {
            guard let splitName = split.name else {
                continue
            }

            let prefix = getPrefix(for: splitName) ?? ""
            if !namesToKeep.contains(splitName), (prefix == "" || !prefixesToKeep.contains(prefix)) {
                toDelete.append(splitName)
            }

        }
        if toDelete.count > 0 {
            splitsStorage.delete(splitNames: toDelete)
        }
    }

    private func getPrefix(for splitName: String) -> String? {
        let kPrefixSeparator = "__"
        if let range = splitName.range(of: kPrefixSeparator),
           range.lowerBound != splitName.startIndex, range.upperBound != splitName.endIndex {
            return String(splitName[range.upperBound...])
        }
        return nil
    }
}
