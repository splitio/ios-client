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

    private let syncWorkerFactory: SyncWorkerFactory
    private let impressionsSyncHelper: ImpressionsRecorderSyncHelper
    private let periodicImpressionsRecorderWoker: PeriodicRecorderWorker
    private var periodicImpressionsCountRecorderWoker: PeriodicRecorderWorker?
    private var flusherImpressionsCountRecorderWorker: RecorderWorker?
    private let flusherImpressionsRecorderWorker: RecorderWorker
    private let splitConfig: SplitClientConfig
    private let impressionsObserver = ImpressionsObserver(size: ServiceConstants.lastSeenImpressionCachSize)
    private let impressionsCounter = ImpressionsCounter()
    private let storageContainer: SplitStorageContainer
    private let telemetryProducer: TelemetryRuntimeProducer?

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper) {

        self.splitConfig = splitConfig
        self.syncWorkerFactory = syncWorkerFactory
        self.storageContainer = storageContainer
        self.flusherImpressionsRecorderWorker =
            syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.periodicImpressionsRecorderWoker =
            syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        self.impressionsSyncHelper = impressionsSyncHelper
        self.telemetryProducer = storageContainer.telemetryStorage

        if isOptimizedImpressionsMode() {
            self.periodicImpressionsCountRecorderWoker
                = syncWorkerFactory.createPeriodicImpressionsCountRecorderWorker()
            self.flusherImpressionsCountRecorderWorker
                = syncWorkerFactory.createImpressionsCountRecorderWorker()
        }
    }

    func start() {
        periodicImpressionsRecorderWoker.start()
        periodicImpressionsCountRecorderWoker?.start()
    }

    func stop() {
        periodicImpressionsCountRecorderWoker?.stop()
        periodicImpressionsRecorderWoker.stop()
    }

    func push(_ impression: KeyImpression) {

        // This should not happen
        guard let featureName = impression.featureName else {
            return
        }

        let impressionToPush = impression.withPreviousTime(
            impressionsObserver.testAndSet(impression: impression))
        if isOptimizedImpressionsMode() {
            impressionsCounter.inc(featureName: featureName, timeframe: impressionToPush.time, amount: 1)
        }

        if !isOptimizedImpressionsMode() || shouldPush(impression: impressionToPush) {
            if impressionsSyncHelper.pushAndCheckFlush(impressionToPush) {
                flusherImpressionsRecorderWorker.flush()
                impressionsSyncHelper.resetAccumulator()
            }
            telemetryProducer?.recordImpressionStats(type: .queued, count: 1)
        } else {
            telemetryProducer?.recordImpressionStats(type: .deduped, count: 1)
        }

    }

    func pause() {
        saveImpressionsCount()
        periodicImpressionsRecorderWoker.pause()
        periodicImpressionsCountRecorderWoker?.pause()
    }

    func resume() {
        periodicImpressionsRecorderWoker.resume()
        periodicImpressionsCountRecorderWoker?.resume()
    }

    func flush() {
        flusherImpressionsRecorderWorker.flush()
        flusherImpressionsCountRecorderWorker?.flush()
        impressionsSyncHelper.resetAccumulator()
    }

    func destroy() {
        periodicImpressionsRecorderWoker.destroy()
        periodicImpressionsCountRecorderWoker?.destroy()
    }

    private func saveImpressionsCount() {
        storageContainer.impressionsCountStorage.pushMany(counts: impressionsCounter.popAll())
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
