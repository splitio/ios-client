//
//  ImpressionsTracker.swift
//  Split
//
//  Created by Javier Avrudsky on 10-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

enum RecordingService {
    case uniqueKeys
    case impressions
    case all
}

protocol ImpressionsTracker: AnyObject {
    func start()
    func pause()
    func resume()
    func stop(_ service: RecordingService)
    func flush()
    func push(_ decoratedImpression: DecoratedImpression)
    func destroy()
    func enableTracking(_ enable: Bool)
    func enablePersistence(_ enable: Bool)
}

class DefaultImpressionsTracker: ImpressionsTracker {
    private let splitConfig: SplitClientConfig

    private let syncWorkerFactory: SyncWorkerFactory
    private var impressionsSyncHelper: ImpressionsRecorderSyncHelper?
    private var periodicImpressionsRecorderWoker: PeriodicRecorderWorker?
    private var periodicImpressionsCountRecorderWoker: PeriodicRecorderWorker?
    private var flusherImpressionsCountRecorderWorker: RecorderWorker?
    private var flusherImpressionsRecorderWorker: RecorderWorker?

    private let impressionsObserver: ImpressionsObserver
    private var impressionsCounter: ImpressionsCounter?

    private var uniqueKeyTracker: UniqueKeyTracker?
    private var flusherUniqueKeysRecorderWorker: RecorderWorker?
    private var periodicUniqueKeysRecorderWorker: PeriodicRecorderWorker?
    private var uniqueKeyFlushChecker: RecorderFlushChecker?

    private let storageContainer: SplitStorageContainer
    private let telemetryProducer: TelemetryRuntimeProducer?

    private var isTrackingEnabled: Bool = true
    private var isPersistenceEnabled: Bool = true

    init(
        splitConfig: SplitClientConfig,
        splitApiFacade: SplitApiFacade,
        storageContainer: SplitStorageContainer,
        syncWorkerFactory: SyncWorkerFactory,
        impressionsSyncHelper: ImpressionsRecorderSyncHelper?,
        uniqueKeyTracker: UniqueKeyTracker?,
        notificationHelper: NotificationHelper?,
        impressionsObserver: ImpressionsObserver) {
        self.splitConfig = splitConfig
        self.syncWorkerFactory = syncWorkerFactory
        self.storageContainer = storageContainer
        self.telemetryProducer = storageContainer.telemetryStorage
        self.uniqueKeyTracker = uniqueKeyTracker
        self.impressionsSyncHelper = impressionsSyncHelper
        self.impressionsObserver = impressionsObserver

        #if os(macOS)
            notificationHelper?.addObserver(for: AppNotification.didEnterBackground) { [weak self] _ in
                if let self = self {
                    self.saveUniqueKeys()
                    self.saveImpressionsCount()
                    self.saveHashedImpressions()
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

    func stop(_ service: RecordingService = .all) {
        if [.all, .impressions].contains(service) {
            periodicImpressionsRecorderWoker?.stop()
            periodicImpressionsCountRecorderWoker?.stop()
        }

        if [.all, .uniqueKeys].contains(service) {
            periodicUniqueKeysRecorderWorker?.stop()
        }
    }

    func push(_ decoratedImpression: DecoratedImpression) {
        if !isTrackingEnabled {
            Logger.v("Impression not tracked because tracking is disabled")
            return
        }

        let impression = decoratedImpression.impression

        // This should not happen
        guard let featureName = impression.featureName else {
            return
        }

        if isNoneImpressionsMode() || decoratedImpression.impressionsDisabled {
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
        saveHashedImpressions()
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
        saveHashedImpressions()
        impressionsObserver.clear()
    }

    func enablePersistence(_ enable: Bool) {
        isPersistenceEnabled = enable
    }

    func enableTracking(_ enable: Bool) {
        isTrackingEnabled = enable
    }

    // MARK: Private methods

    private func saveImpressionsCount() {
        if !isPersistenceEnabled {
            return
        }
        if let counts = impressionsCounter?.popAll() {
            storageContainer.impressionsCountStorage.pushMany(counts: counts)
        }
    }

    private func saveUniqueKeys() {
        // Just double checking
        if !isPersistenceEnabled {
            return
        }

        uniqueKeyTracker?.saveAndClear()
    }

    private func saveHashedImpressions() {
        impressionsObserver.saveHashes()
    }

    private func setupImpressionsMode() {
        createUniqueKeysRecorder()
        createImpressionsCountRecorder()

        if splitConfig.$impressionsMode == .debug || splitConfig.$impressionsMode == .optimized {
            createImpressionsRecorder()
        }
    }

    private func createImpressionsRecorder() {
        flusherImpressionsRecorderWorker =
            syncWorkerFactory.createImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
        periodicImpressionsRecorderWoker =
            syncWorkerFactory.createPeriodicImpressionsRecorderWorker(syncHelper: impressionsSyncHelper)
    }

    private func createImpressionsCountRecorder() {
        periodicImpressionsCountRecorderWoker
            = syncWorkerFactory.createPeriodicImpressionsCountRecorderWorker()
        flusherImpressionsCountRecorderWorker
            = syncWorkerFactory.createImpressionsCountRecorderWorker()
        impressionsCounter = ImpressionsCounter()
    }

    private func createUniqueKeysRecorder() {
        periodicUniqueKeysRecorderWorker
            = syncWorkerFactory.createPeriodicUniqueKeyRecorderWorker(flusherChecker: uniqueKeyFlushChecker)
        flusherUniqueKeysRecorderWorker
            = syncWorkerFactory.createUniqueKeyRecorderWorker(flusherChecker: uniqueKeyFlushChecker)
    }

    private func isOptimizedImpressionsMode() -> Bool {
        return ImpressionsMode.optimized == splitConfig.$impressionsMode
    }

    private func isNoneImpressionsMode() -> Bool {
        return ImpressionsMode.none == splitConfig.$impressionsMode
    }

    private func shouldPush(impression: KeyImpression) -> Bool {
        guard let previousTime = impression.previousTime else {
            return true
        }
        return Date.truncateTimeframe(millis: previousTime) != Date.truncateTimeframe(millis: impression.time)
    }
}
