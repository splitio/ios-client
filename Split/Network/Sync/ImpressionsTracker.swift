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

    private let uniqueKeyTracker: UniqueKeyTracker?
    private let uniqueKeysRecorderWorker: RecorderWorker?
    private let periodicUniqueKeyRecorderWorker: PeriodicRecorderWorker?

    private let storageContainer: SplitStorageContainer
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let uniqueKeyFlushChecker: RecorderFlushChecker?

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper?,
         uniqueKeyTracker: UniqueKeyTracker?) {

        self.splitConfig = splitConfig
        self.syncWorkerFactory = syncWorkerFactory
        self.storageContainer = storageContainer
        self.telemetryProducer = storageContainer.telemetryStorage
        self.uniqueKeyTracker = uniqueKeyTracker
        self.impressionsSyncHelper = impressionsSyncHelper
        setupImpressionsMode()
    }

    func start() {
        periodicImpressionsRecorderWoker?.start()
        periodicImpressionsCountRecorderWoker?.start()
    }

    func stop() {
        periodicImpressionsRecorderWoker?.stop()
        periodicImpressionsCountRecorderWoker?.stop()
    }

    func push(_ impression: KeyImpression) {

        // This should not happen
        guard let featureName = impression.featureName else {
            return
        }

        if isNoneImpressionsMode() {
            uniqueKeyTracker?.track(userKey: impression.keyName, featureName: featureName)
            if uniqueKeyFlushChecker?
                .checkIfFlushIsNeeded(sizeInBytes: ServiceConstants.estimatedUniqueKeySizeInBytes) ?? false {
                uniqueKeyTracker?.saveAndClear()

                uni.
            }
            return
        }

        let impressionToPush = impression.withPreviousTime(
            impressionsObserver.testAndSet(impression: impression))
        if isOptimizedImpressionsMode() {
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
    }

    func resume() {
        periodicImpressionsRecorderWoker?.resume()
        periodicImpressionsCountRecorderWoker?.resume()
    }

    func flush() {
        flusherImpressionsRecorderWorker?.flush()
        flusherImpressionsCountRecorderWorker?.flush()
        impressionsSyncHelper?.resetAccumulator()
    }

    func destroy() {
        periodicImpressionsRecorderWoker?.destroy()
        periodicImpressionsCountRecorderWoker?.destroy()
    }

    private func saveImpressionsCount() {
        if isOptimizedImpressionsMode(), let counts = impressionsCounter?.popAll() {
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
            // TODO: Setup send unique key recorder
            createImpressionsCountRecorder()
            Logger.d("Missing none setup") // To be removed
        default:
            Logger.d("Impression mode set: \(splitConfig.finalImpressionsMode)")
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
