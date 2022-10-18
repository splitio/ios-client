//
//  ImpressionsTracker.swift
//  Split
//
//  Created by Javier Avrudsky on 10-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ImpressionsTracker {
    func start()
    func pause()
    func resume()
    func stop()
    func flush()
    func push(_ impression: KeyImpression)
    func destroy()
}

class DefaultImpressionsTracker: ImpressionsTracker {

    private let splitConfig: SplitClientConfig

    private let syncWorkerFactory: SyncWorkerFactory
    private var impressionsSyncHelper: ImpressionsRecorderSyncHelper?
    private var periodicImpressionsRecorderWoker: PeriodicRecorderWorker?
    private var periodicImpressionsCountRecorderWoker: PeriodicRecorderWorker?
    private var flusherImpressionsCountRecorderWorker: RecorderWorker?
    private var flusherImpressionsRecorderWorker: RecorderWorker?

    private let impressionsObserver = ImpressionsObserver(size: ServiceConstants.lastSeenImpressionCachSize)
    private var impressionsCounter: ImpressionsCounter?

    private var uniqueKeyTracker: UniqueKeyTracker?
    private var flusherUniqueKeysRecorderWorker: RecorderWorker?
    private var periodicUniqueKeysRecorderWorker: PeriodicRecorderWorker?
    private var uniqueKeyFlushChecker: RecorderFlushChecker?

    private let storageContainer: SplitStorageContainer
    private let telemetryProducer: TelemetryRuntimeProducer?

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper?,
         uniqueKeyTracker: UniqueKeyTracker?,
         notificationHelper: NotificationHelper?) {

        self.splitConfig = splitConfig
        self.syncWorkerFactory = syncWorkerFactory
        self.storageContainer = storageContainer
        self.telemetryProducer = storageContainer.telemetryStorage
        self.uniqueKeyTracker = uniqueKeyTracker
        self.impressionsSyncHelper = impressionsSyncHelper

#if os(macOS)
        notificationHelper?.addObserver(for: AppNotification.didEnterBackground) { [weak self] in
            if let self = self {
                self.saveUniqueKeys()
                self.saveImpressionsCount()
            }
        }
#endif
        setupImpressionsMode()
    }

    func start() {
        periodicImpressionsRecorderWoker?.start()
        periodicImpressionsCountRecorderWoker?.start()
        periodicUniqueKeysRecorderWorker?.start()
    }

    func stop() {
        periodicImpressionsRecorderWoker?.stop()
        periodicImpressionsCountRecorderWoker?.stop()
        periodicUniqueKeysRecorderWorker?.stop()
    }

    func push(_ impression: KeyImpression) {

        // This should not happen
        guard let featureName = impression.featureName else {
            return
        }

        if isNoneImpressionsMode() {
            uniqueKeyTracker?.track(userKey: impression.keyName, featureName: featureName)
            impressionsCounter?.inc(featureName: featureName, timeframe: impression.time, amount: 1)
            if uniqueKeyFlushChecker?
                .checkIfFlushIsNeeded(sizeInBytes: ServiceConstants.estimatedUniqueKeySizeInBytes) ?? false {
                uniqueKeyTracker?.saveAndClear()
                flusherUniqueKeysRecorderWorker?.flush()
            }
            return
        }

        let impressionToPush = impression.withPreviousTime(
            impressionsObserver.testAndSet(impression: impression))
        if isOptimizedImpressionsMode() &&
            impressionToPush.previousTime ?? 0 > 0 {
            impressionsCounter?.inc(featureName: featureName, timeframe: impressionToPush.time, amount: 1)
        }

        if !isOptimizedImpressionsMode() || shouldPush(impression: impressionToPush) {
            if impressionsSyncHelper?.pushAndCheckFlush(impressionToPush) ?? false {
                flusherImpressionsRecorderWorker?.flush()
                impressionsSyncHelper?.resetAccumulator()
            }
            telemetryProducer?.recordImpressionStats(type: .queued, count: 1)
        } else {
            telemetryProducer?.recordImpressionStats(type: .deduped, count: 1)
        }

    }

    func pause() {
        saveImpressionsCount()
        saveUniqueKeys()
        periodicImpressionsRecorderWoker?.pause()
        periodicImpressionsCountRecorderWoker?.pause()
        periodicUniqueKeysRecorderWorker?.pause()
    }

    func resume() {
        periodicImpressionsRecorderWoker?.resume()
        periodicImpressionsCountRecorderWoker?.resume()
        periodicUniqueKeysRecorderWorker?.resume()
    }

    func flush() {
        saveImpressionsCount()
        saveUniqueKeys()
        flusherImpressionsRecorderWorker?.flush()
        flusherImpressionsCountRecorderWorker?.flush()
        flusherUniqueKeysRecorderWorker?.flush()
        impressionsSyncHelper?.resetAccumulator()
        uniqueKeyFlushChecker?.update(count: 0, bytes: 0)
    }

    func destroy() {
        periodicImpressionsRecorderWoker?.destroy()
        periodicImpressionsCountRecorderWoker?.destroy()
        periodicUniqueKeysRecorderWorker?.destroy()
        impressionsObserver.stop()
    }

    private func saveImpressionsCount() {
        if (isOptimizedImpressionsMode() || isNoneImpressionsMode()),
           let counts = impressionsCounter?.popAll() {
            storageContainer.impressionsCountStorage.pushMany(counts: counts)
        }
    }

    private func saveUniqueKeys() {
        // Just doble checking
        if isNoneImpressionsMode() {
            uniqueKeyTracker?.saveAndClear()
        }
    }

    private func setupImpressionsMode() {

        switch splitConfig.finalImpressionsMode {
        case .optimized:
            createImpressionsRecorder()
            createImpressionsCountRecorder()
        case .debug:
            createImpressionsRecorder()
        case .none:
            createUniqueKeysRecorder()
            createImpressionsCountRecorder()
        }
    }

    private func createImpressionsRecorder() {
        flusherImpressionsRecorderWorker =
            syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        periodicImpressionsRecorderWoker =
            syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
    }

    private func createImpressionsCountRecorder() {
        self.periodicImpressionsCountRecorderWoker
        = syncWorkerFactory.createPeriodicImpressionsCountRecorderWorker()
        self.flusherImpressionsCountRecorderWorker
        = syncWorkerFactory.createImpressionsCountRecorderWorker()
        impressionsCounter = ImpressionsCounter()
    }

    private func createUniqueKeysRecorder() {
        self.periodicUniqueKeysRecorderWorker
        = syncWorkerFactory.createPeriodicUniqueKeyRecorderWorker(flusherChecker: uniqueKeyFlushChecker)
        self.flusherUniqueKeysRecorderWorker
        = syncWorkerFactory.createUniqueKeyRecorderWorker(flusherChecker: uniqueKeyFlushChecker)
    }

    private func isOptimizedImpressionsMode() -> Bool {
        return ImpressionsMode.optimized == splitConfig.finalImpressionsMode
    }

    private func isNoneImpressionsMode() -> Bool {
        return ImpressionsMode.none == splitConfig.finalImpressionsMode
    }

    private func shouldPush(impression: KeyImpression) -> Bool {
        guard let previousTime = impression.previousTime else {
            return true
        }
        return Date.truncateTimeframe(millis: previousTime) != Date.truncateTimeframe(millis: impression.time)
    }
}
