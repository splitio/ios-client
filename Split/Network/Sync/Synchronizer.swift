//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol ImpressionLogger {
    func pushImpression(impression: KeyImpression)
}

protocol Synchronizer: ImpressionLogger {
    func loadAndSynchronizeSplits()
    func loadMySegmentsFromCache()
    func loadAttributesFromCache()
    func syncAll()
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func forceMySegmentsSync()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startPeriodicRecording()
    func stopPeriodicRecording()
    func pushEvent(event: EventDTO)
    func notifiySegmentsUpdated()
    func notifySplitKilled()
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
    let impressionsCountStorage: PersistentImpressionsCountStorage
    let eventsStorage: PersistentEventsStorage
    let attributesStorage: AttributesStorage
    let telemetryStorage: TelemetryStorage?
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
    private let mySegmentsForcedSyncWorker: RetryableSyncWorker
    private let periodicImpressionsRecorderWoker: PeriodicRecorderWorker
    private var periodicImpressionsCountRecorderWoker: PeriodicRecorderWorker?
    private var flusherImpressionsCountRecorderWorker: RecorderWorker?
    private let flusherImpressionsRecorderWorker: RecorderWorker
    private let periodicEventsRecorderWorker: PeriodicRecorderWorker
    private let flusherEventsRecorderWorker: RecorderWorker

    private let eventsSyncHelper: EventsRecorderSyncHelper
    private let splitsFilterQueryString: String
    private let splitEventsManager: SplitEventsManager
    private let impressionsObserver = ImpressionsObserver(size: ServiceConstants.lastSeenImpressionCachSize)
    private let impressionsCounter = ImpressionsCounter()
    private let flushQueue = DispatchQueue(label: "split-flush-queue", target: DispatchQueue.global())

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         eventsSyncHelper: EventsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
        = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         splitEventsManager: SplitEventsManager) {

        self.splitConfig = splitConfig
        self.splitApiFacade = splitApiFacade
        self.splitStorageContainer = splitStorageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog
        self.periodicSplitsSyncWorker = syncWorkerFactory.createPeriodicSplitsSyncWorker()
        self.periodicMySegmentsSyncWorker = syncWorkerFactory.createPeriodicMySegmentsSyncWorker()
        self.splitsSyncWorker = syncWorkerFactory.createRetryableSplitsSyncWorker()
        self.mySegmentsSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(avoidCache: false)
        self.mySegmentsForcedSyncWorker = syncWorkerFactory.createRetryableMySegmentsSyncWorker(avoidCache: true)
        self.flusherImpressionsRecorderWorker =
            syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.periodicImpressionsRecorderWoker =
            syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.flusherEventsRecorderWorker = syncWorkerFactory.createEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.periodicEventsRecorderWorker =
            syncWorkerFactory.createPeriodicEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.impressionsSyncHelper = impressionsSyncHelper
        self.eventsSyncHelper = eventsSyncHelper
        self.splitsFilterQueryString = splitsFilterQueryString
        self.splitEventsManager = splitEventsManager

        if isOptimizedImpressionsMode() {
            self.periodicImpressionsCountRecorderWoker
                = syncWorkerFactory.createPeriodicImpressionsCountRecorderWorker()
            self.flusherImpressionsCountRecorderWorker
                = syncWorkerFactory.createImpressionsCountRecorderWorker()
        }
    }

    func loadAndSynchronizeSplits() {
        let splitsStorage = self.splitStorageContainer.splitsStorage
        DispatchQueue.global().async {
            self.filterSplitsInCache()
            splitsStorage.loadLocal()
            if splitsStorage.getAll().count > 0 {
                self.splitEventsManager.notifyInternalEvent(.splitsLoadedFromCache)
            }
            self.synchronizeSplits()
        }
    }

    func loadMySegmentsFromCache() {
        DispatchQueue.global().async {
            self.splitStorageContainer.mySegmentsStorage.loadLocal()
            self.splitEventsManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
        }
    }

    func loadAttributesFromCache() {
        DispatchQueue.global().async {
            self.splitStorageContainer.attributesStorage.loadLocal()
            self.splitEventsManager.notifyInternalEvent(.attributesLoadedFromCache)
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

    func forceMySegmentsSync() {
        mySegmentsForcedSyncWorker.start()
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
        periodicEventsRecorderWorker.start()
        periodicImpressionsCountRecorderWoker?.start()
    }

    func stopPeriodicRecording() {
        periodicImpressionsRecorderWoker.stop()
        periodicEventsRecorderWorker.stop()
        periodicImpressionsCountRecorderWoker?.stop()
    }

    func pushEvent(event: EventDTO) {
        flushQueue.async {
            if self.eventsSyncHelper.pushAndCheckFlush(event) {
                self.flusherEventsRecorderWorker.flush()
                self.eventsSyncHelper.resetAccumulator()
            }
        }
    }

    func pushImpression(impression: KeyImpression) {

        // This should not happen
        guard let featureName = impression.featureName else {
            return
        }

        flushQueue.async {
            let impressionToPush = impression.withPreviousTime(
                self.impressionsObserver.testAndSet(impression: impression))
            if self.isOptimizedImpressionsMode() {
                self.impressionsCounter.inc(featureName: featureName, timeframe: impressionToPush.time, amount: 1)
            }

            if !self.isOptimizedImpressionsMode() || self.shouldPush(impression: impressionToPush) {
                if self.impressionsSyncHelper.pushAndCheckFlush(impressionToPush) {
                    self.flusherImpressionsRecorderWorker.flush()
                    self.impressionsSyncHelper.resetAccumulator()

                }
            }
        }
    }

    func notifiySegmentsUpdated() {
        splitEventsManager.notifyInternalEvent(.mySegmentsUpdated)
    }

    func notifySplitKilled() {
        splitEventsManager.notifyInternalEvent(.splitKilledNotification)
    }

    func pause() {
        saveImpressionsCount()
        periodicSplitsSyncWorker.pause()
        periodicMySegmentsSyncWorker.pause()
        periodicEventsRecorderWorker.pause()
        periodicImpressionsRecorderWoker.pause()
        periodicImpressionsCountRecorderWoker?.pause()
    }

    func resume() {
        periodicSplitsSyncWorker.resume()
        periodicMySegmentsSyncWorker.resume()
        periodicEventsRecorderWorker.resume()
        periodicImpressionsRecorderWoker.resume()
        periodicImpressionsCountRecorderWoker?.resume()
    }

    func flush() {
        flushQueue.async {
            self.flusherImpressionsRecorderWorker.flush()
            self.flusherEventsRecorderWorker.flush()
            self.flusherImpressionsCountRecorderWorker?.flush()
            self.eventsSyncHelper.resetAccumulator()
            self.impressionsSyncHelper.resetAccumulator()
        }
    }

    func destroy() {
        splitsSyncWorker.stop()
        mySegmentsSyncWorker.stop()
        periodicSplitsSyncWorker.stop()
        periodicMySegmentsSyncWorker.stop()
        mySegmentsForcedSyncWorker.stop()
        periodicSplitsSyncWorker.destroy()
        periodicMySegmentsSyncWorker.destroy()
        periodicImpressionsRecorderWoker.destroy()
        periodicEventsRecorderWorker.destroy()
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
            splitStorageContainer.splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: -1)
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

    private func saveImpressionsCount() {
        splitStorageContainer.impressionsCountStorage.pushMany(counts: impressionsCounter.popAll())
    }

    private func isOptimizedImpressionsMode() -> Bool {
        return ImpressionsMode.optimized == splitConfig.finalImpressionsMode
    }

    private func shouldPush(impression: KeyImpression) -> Bool {
        guard let previousTime = impression.previousTime else {
            return true
        }
        return Date.truncateTimeframe(millis: previousTime) != Date.truncateTimeframe(millis: impression.time)
    }
}
