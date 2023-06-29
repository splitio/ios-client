//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer: ImpressionLogger {
    func start(forKey key: Key)
    func loadAndSynchronizeSplits()
    func loadMySegmentsFromCache()
    func loadAttributesFromCache()
    func synchronizeMySegments()
    func loadMySegmentsFromCache(forKey key: String)
    func loadAttributesFromCache(forKey key: String)
    func syncAll()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments(forKey key: String)
    func synchronizeTelemetryConfig()
    func forceMySegmentsSync(forKey key: String)
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startRecordingUserData()
    func stopRecordingUserData()
    func startRecordingTelemetry()
    func stopRecordingTelemetry()
    func pushEvent(event: EventDTO)
    func notifyFeatureFlagsUpdated()
    func notifySegmentsUpdated(forKey key: String)
    func notifySplitKilled()
    func pause()
    func resume()
    func flush()
    func destroy()
}

class DefaultSynchronizer: Synchronizer {

    private let splitConfig: SplitClientConfig
    private let splitStorageContainer: SplitStorageContainer

    private let splitEventsManager: SplitEventsManager

    private let flushQueue = DispatchQueue(label: "split-flush-queue", target: DispatchQueue.global())
    private let byKeySynchronizer: ByKeySynchronizer
    private let defaultUserKey: String

    private let impressionsTracker: ImpressionsTracker
    private let eventsSynchronizer: EventsSynchronizer
    private let telemetrySynchronizer: TelemetrySynchronizer?
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let featureFlagsSynchronizer: FeatureFlagsSynchronizer

    private var isDestroyed = Atomic(false)

    init(splitConfig: SplitClientConfig,
         defaultUserKey: String,
         featureFlagsSynchronizer: FeatureFlagsSynchronizer,
         telemetrySynchronizer: TelemetrySynchronizer?,
         byKeyFacade: ByKeyFacade,
         splitStorageContainer: SplitStorageContainer,
         impressionsTracker: ImpressionsTracker,
         eventsSynchronizer: EventsSynchronizer,
         splitEventsManager: SplitEventsManager) {

        self.defaultUserKey = defaultUserKey
        self.splitConfig = splitConfig
        self.splitStorageContainer = splitStorageContainer

        self.featureFlagsSynchronizer = featureFlagsSynchronizer
        self.impressionsTracker = impressionsTracker
        self.eventsSynchronizer = eventsSynchronizer
        self.splitEventsManager = splitEventsManager
        self.telemetryProducer = splitStorageContainer.telemetryStorage
        self.telemetrySynchronizer = telemetrySynchronizer
        self.byKeySynchronizer = byKeyFacade

    }

    func loadAndSynchronizeSplits() {
        self.featureFlagsSynchronizer.loadAndSynchronize()
    }

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCache(forKey: defaultUserKey)
    }

    func loadAttributesFromCache() {
        loadAttributesFromCache(forKey: defaultUserKey)
    }

    func loadMySegmentsFromCache(forKey key: String) {
        byKeySynchronizer.loadMySegmentsFromCache(forKey: key)
    }

    func loadAttributesFromCache(forKey key: String) {
        byKeySynchronizer.loadAttributesFromCache(forKey: key)
    }

    func start(forKey key: Key) {
        byKeySynchronizer.startSync(forKey: key)
    }

    func syncAll() {
        print("SYNC ALL")
        synchronizeSplits()
        byKeySynchronizer.syncAll()
    }

    func synchronizeSplits(changeNumber: Int64) {
        runIfSyncEnabled {
            self.featureFlagsSynchronizer.synchronize(changeNumber: changeNumber)
        }
    }

    func synchronizeMySegments() {
        self.synchronizeMySegments(forKey: defaultUserKey)
    }

    func synchronizeMySegments(forKey key: String) {
        byKeySynchronizer.syncMySegments(forKey: key)
    }

    func forceMySegmentsSync(forKey key: String) {
        runIfSyncEnabled {
            self.byKeySynchronizer.forceMySegmentsSync(forKey: key)
        }
    }

    func synchronizeTelemetryConfig() {
        telemetrySynchronizer?.synchronizeConfig()
    }

    func startPeriodicFetching() {
        runIfSyncEnabled {
            featureFlagsSynchronizer.startPeriodicSync()
            byKeySynchronizer.startPeriodicSync()
            recordSyncModeEvent(TelemetryStreamingEventValue.syncModePolling)
        }
    }

    func stopPeriodicFetching() {
        featureFlagsSynchronizer.stopPeriodicSync()
        byKeySynchronizer.stopPeriodicSync()
        recordSyncModeEvent(TelemetryStreamingEventValue.syncModeStreaming)
    }

    func startRecordingUserData() {
        impressionsTracker.start()
        eventsSynchronizer.start()
    }

    func stopRecordingUserData() {
        impressionsTracker.stop()
        eventsSynchronizer.stop()
    }

    func startRecordingTelemetry() {
        telemetrySynchronizer?.start()
    }

    func stopRecordingTelemetry() {
        telemetrySynchronizer?.destroy()
    }

    func pushEvent(event: EventDTO) {
        flushQueue.async { [weak self] in

            guard let self = self else { return }
            self.eventsSynchronizer.push(event)
        }
    }

    func pushImpression(impression: KeyImpression) {

        flushQueue.async { [weak self] in
            guard let self = self else { return }

            self.impressionsTracker.push(impression)
        }
    }

    func notifyFeatureFlagsUpdated() {
        featureFlagsSynchronizer.notifyUpdated()
    }

    func notifySegmentsUpdated(forKey key: String) {
        byKeySynchronizer.notifyMySegmentsUpdated(forKey: key)
    }

    func notifySplitKilled() {
        featureFlagsSynchronizer.notifyKilled()
    }

    func pause() {
        impressionsTracker.pause()
        featureFlagsSynchronizer.pause()
        byKeySynchronizer.pause()
        eventsSynchronizer.pause()
        telemetrySynchronizer?.synchronizeStats()
        telemetrySynchronizer?.pause()
    }

    func resume() {
        impressionsTracker.resume()
        featureFlagsSynchronizer.resume()
        byKeySynchronizer.resume()
        eventsSynchronizer.resume()
        telemetrySynchronizer?.resume()
    }

    func flush() {
        flushQueue.async {  [weak self] in
            guard let self = self else { return }

            self.impressionsTracker.flush()
            self.eventsSynchronizer.flush()
            self.telemetrySynchronizer?.synchronizeStats()
        }
    }

    func destroy() {
        isDestroyed.set(true)
        featureFlagsSynchronizer.stop()
        byKeySynchronizer.stop()
        eventsSynchronizer.destroy()
        impressionsTracker.destroy()
    }

    // MARK: Private
    private func synchronizeSplits() {
        print("BEF SYN FF")
        self.featureFlagsSynchronizer.synchronize()
        print("AF SYN FF")
    }

    private func recordSyncModeEvent(_ mode: Int64) {
        if splitConfig.streamingEnabled && !isDestroyed.value {
            telemetryProducer?.recordStreamingEvent(type: .syncModeUpdate,
                                                    data: mode)
        }
    }

    @inline(__always)
    private func runIfSyncEnabled(action: () -> Void) {
        if self.splitConfig.syncEnabled {
            action()
        }
    }
}
