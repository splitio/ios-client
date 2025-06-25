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
    func loadSplitsFromCache()
    func loadMySegmentsFromCache()
    func loadAttributesFromCache()
    func synchronizeSplits()
    func synchronizeMySegments()
    func loadMySegmentsFromCache(forKey key: String)
    func loadAttributesFromCache(forKey key: String)
    func syncAll()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeRuleBasedSegments(changeNumber: Int64)
    func synchronizeMySegments(forKey key: String)
    func synchronizeTelemetryConfig()
    func forceMySegmentsSync(forKey key: String, changeNumbers: SegmentsChangeNumber, delay: Int64)
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startRecordingUserData()
    func stopRecordingUserData()
    func startRecordingTelemetry()
    func stopRecordingTelemetry()
    func pushEvent(event: EventDTO)
    func notifyFeatureFlagsUpdated(flagsList: [String])
    func notifySegmentsUpdated(forKey key: String, _ metadata: EventMetadata?)
    func notifyLargeSegmentsUpdated(forKey key: String, _ metadata: EventMetadata?)
    func notifySplitKilled(flag: String)
    func pause()
    func resume()
    func flush()
    func destroy()

    func disableSdk()
    func disableEvents()
    func disableTelemetry()
}

class DefaultSynchronizer: Synchronizer {

    private let splitConfig: SplitClientConfig
    private let splitStorageContainer: SplitStorageContainer

    private let splitEventsManager: SplitEventsManager

    private let flushQueue = DispatchQueue(label: "split-flush-queue", target: DispatchQueue.general)
    private let byKeySynchronizer: ByKeySynchronizer
    private let defaultUserKey: String

    private let impressionsTracker: ImpressionsTracker
    private let eventsSynchronizer: EventsSynchronizer
    private let telemetrySynchronizer: TelemetrySynchronizer?
    private let telemetryProducer: TelemetryRuntimeProducer?
    private let featureFlagsSynchronizer: FeatureFlagsSynchronizer

    // These three variables indicates what
    // endpoints are not available because
    // pinned credential validation has failed
    private let isSdkDisabled = Atomic(false)
    private let isEventsDisabled = Atomic(false)
    private let isTelemetryDisabled = Atomic(false)

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

    func loadSplitsFromCache() {
        self.featureFlagsSynchronizer.load()
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
        synchronizeSplits()
        byKeySynchronizer.syncAll()
    }

    func synchronizeSplits(changeNumber: Int64) {
        runIfSyncEnabled {
            self.featureFlagsSynchronizer.synchronize(changeNumber: changeNumber, rbsChangeNumber: nil)
        }
    }

    func synchronizeRuleBasedSegments(changeNumber: Int64) {
        runIfSyncEnabled {
            self.featureFlagsSynchronizer.synchronize(changeNumber: nil, rbsChangeNumber: changeNumber)
        }
    }

    func synchronizeMySegments() {
        self.synchronizeMySegments(forKey: defaultUserKey)
    }

    func synchronizeMySegments(forKey key: String) {
        byKeySynchronizer.syncMySegments(forKey: key)
    }

    func forceMySegmentsSync(forKey key: String, changeNumbers: SegmentsChangeNumber, delay: Int64) {
        runIfSyncEnabled {
            self.byKeySynchronizer.forceMySegmentsSync(forKey: key,
                                                       changeNumbers: changeNumbers,
                                                       delay: delay)
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
        if isEventsDisabled.value {
            return
        }
        impressionsTracker.start()
        eventsSynchronizer.start()
    }

    func stopRecordingUserData() {
        impressionsTracker.stop(.all)
        eventsSynchronizer.stop()
    }

    func startRecordingTelemetry() {
        if isTelemetryDisabled.value {
            return
        }
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

    func pushImpression(impression: DecoratedImpression) {
        flushQueue.async { [weak self] in
            guard let self = self else { return }

            self.impressionsTracker.push(impression)
        }
    }

    func notifyFeatureFlagsUpdated(flagsList: [String]) {
        featureFlagsSynchronizer.notifyUpdated(flagsList: flagsList)
    }

    func notifySegmentsUpdated(forKey key: String, _ metadata: EventMetadata? = nil) {
        byKeySynchronizer.notifyMySegmentsUpdated(forKey: key, metadata)
    }

    func notifyLargeSegmentsUpdated(forKey key: String, _ metadata: EventMetadata? = nil) {
        byKeySynchronizer.notifyMyLargeSegmentsUpdated(forKey: key, metadata)
    }

    func notifySplitKilled(flag: String) {
        featureFlagsSynchronizer.notifyKilled(flag: flag)
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
        featureFlagsSynchronizer.destroy()
        byKeySynchronizer.stop()
        eventsSynchronizer.destroy()
        impressionsTracker.destroy()
    }

    func synchronizeSplits() {
        self.featureFlagsSynchronizer.synchronize()
    }

    func disableSdk() {
        isSdkDisabled.set(true)
        featureFlagsSynchronizer.destroy()
        byKeySynchronizer.stopSync()
    }

    // Unique keys are sent to telemetry endpoint
    // Because of this function disables data being sent
    // to telemetry endpoint, unique keys submitter is
    // stopped too
    func disableTelemetry() {
        isTelemetryDisabled.set(true)
        // Unique keys are sent to telemetry endpoint
        impressionsTracker.stop(.uniqueKeys)
        if splitConfig.isTelemetryEnabled {
            stopRecordingTelemetry()
        }
    }

    func disableEvents() {
        isEventsDisabled.set(true)
        impressionsTracker.stop(.impressions)
        eventsSynchronizer.stop()
    }

    // MARK: Private
    private func recordSyncModeEvent(_ mode: Int64) {
        if splitConfig.streamingEnabled && !isDestroyed.value {
            telemetryProducer?.recordStreamingEvent(type: .syncModeUpdate,
                                                    data: mode)
        }
    }

    @inline(__always)
    private func runIfSyncEnabled(action: () -> Void) {
        if self.splitConfig.syncEnabled, !self.isSdkDisabled.value {
            action()
        }
    }
}
