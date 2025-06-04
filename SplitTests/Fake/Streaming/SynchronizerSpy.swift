//
//  SynchronizerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SynchronizerSpy: Synchronizer {
    var splitSynchronizer: Synchronizer

    var loadAndSynchronizeSplitsCalled = false
    var loadMySegmentsFromCacheCalled = false
    var loadMyLargeSegmentsFromCacheCalled = false
    var loadAttributesFromCacheCalled = false
    var syncAllCalled = false
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeRuleBasedSegmentsCalled = false
    var synchronizeMySegmentsCalled = false
    var synchronizeMyLargeSegmentsCalled = false
    var forceMySegmentsCalledCount = 0
    var startPeriodicFetchingCalled = false
    var stopPeriodicFetchingCalled = false
    var pushEventCalled = false
    var pushImpressionCalled = false
    var flushCalled = false
    var destroyCalled = false

    var notifyMySegmentsUpdatedCalled = false
    var notifyMyLargeSegmentsUpdatedCalled = false
    var notifySplitKilledCalled = false

    var syncSplitsExp: XCTestExpectation?
    var syncSplitsChangeNumberExp: XCTestExpectation?
    var syncRuleBasedSegmentsExp: XCTestExpectation?

    var startPeriodicFetchingExp: XCTestExpectation?
    var stopPeriodicFetchingExp: XCTestExpectation?

    let defaultUserKey: String


    var forceMySegmentsSyncCalled = [String: Bool]()
    var forceMySegmentsSyncCount = [String: Int]()
    var forceMyLargeSegmentsSyncCalled = [String: Bool]()
    var forceMyLargeSegmentsSyncCount = [String: Int]()
    var disableTelemetryCalled = true
    var disableEventsCalled = true
    var disableSdkCalled = true

    var forceMySegmentsCalledParams = [String: ForceMySegmentsParams]()

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
        self.splitSynchronizer = DefaultSynchronizer(splitConfig: splitConfig,
                                                     defaultUserKey: defaultUserKey,
                                                     featureFlagsSynchronizer: featureFlagsSynchronizer,
                                                     telemetrySynchronizer: telemetrySynchronizer,
                                                     byKeyFacade: byKeyFacade,
                                                     splitStorageContainer: splitStorageContainer,
                                                     impressionsTracker: impressionsTracker,
                                                     eventsSynchronizer: eventsSynchronizer,
                                                     splitEventsManager: splitEventsManager)
    }

    func synchronizeSplits() {
        synchronizeSplitsCalled = true
        splitSynchronizer.synchronizeSplits()
    }

    func loadSplitsFromCache() {
        loadAndSynchronizeSplitsCalled = true
        splitSynchronizer.loadSplitsFromCache()
    }

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCacheCalled = true
        splitSynchronizer.loadMySegmentsFromCache()
    }

    func loadAttributesFromCache() {
        loadAttributesFromCacheCalled = true
        splitSynchronizer.loadAttributesFromCache()
    }

    func syncAll() {
        syncAllCalled = true
        splitSynchronizer.syncAll()
    }

    func synchronizeTelemetryConfig() {
        syncAllCalled = true
        splitSynchronizer.syncAll()
    }

    func startPeriodicFetching() {
        startPeriodicFetchingCalled = true
        splitSynchronizer.startPeriodicFetching()
        if let exp = startPeriodicFetchingExp {
            exp.fulfill()
        }
    }

    func stopPeriodicFetching() {
        stopPeriodicFetchingCalled = true
        splitSynchronizer.stopPeriodicFetching()
        if let exp = stopPeriodicFetchingExp {
            exp.fulfill()
        }
    }

    var startRecordingUserDataCalled = false
    func startRecordingUserData() {
        startRecordingUserDataCalled = true
        splitSynchronizer.startRecordingUserData()
    }

    var stopRecordingUserDataCalled = false
    func stopRecordingUserData() {
        stopRecordingUserDataCalled = true
        splitSynchronizer.stopRecordingUserData()
    }

    var startRecordingTelemetryCalled = false
    func startRecordingTelemetry() {
        startRecordingTelemetryCalled = true
        splitSynchronizer.startRecordingTelemetry()
    }

    var stopRecordingTelemetryCalled = false
    func stopRecordingTelemetry() {
        stopRecordingTelemetryCalled = false
        splitSynchronizer.stopRecordingTelemetry()
    }

    func pushEvent(event: EventDTO) {
        pushEventCalled = true
        splitSynchronizer.pushEvent(event: event)
    }

    func pushImpression(impression: DecoratedImpression) {
        pushImpressionCalled = true
        splitSynchronizer.pushImpression(impression: impression)
    }

    func flush() {
        flushCalled = true
        splitSynchronizer.flush()
    }

    func destroy() {
        destroyCalled = true
        splitSynchronizer.destroy()
    }

    func synchronizeMySegments() {
        synchronizeMySegments(forKey: defaultUserKey)
    }

    func synchronizeSplits(changeNumber: Int64) {
        synchronizeSplitsChangeNumberCalled = true
        splitSynchronizer.synchronizeSplits(changeNumber: changeNumber)
        if let exp = syncSplitsChangeNumberExp {
            exp.fulfill()
        }
    }

    func synchronizeRuleBasedSegments(changeNumber: Int64) {
        synchronizeRuleBasedSegmentsCalled = true
        splitSynchronizer.synchronizeRuleBasedSegments(changeNumber: changeNumber)
        if let exp = syncRuleBasedSegmentsExp {
            exp.fulfill()
        }
    }

    func pause() {
        splitSynchronizer.pause()
    }

    func resume() {
        splitSynchronizer.resume()
    }

    func notifySegmentsUpdated(forKey key: String) {
        notifyMySegmentsUpdatedCalled = true
        splitSynchronizer.notifySegmentsUpdated(forKey: key)
    }

    func notifyLargeSegmentsUpdated(forKey key: String) {
        notifyMyLargeSegmentsUpdatedCalled = true
        splitSynchronizer.notifyLargeSegmentsUpdated(forKey: key)
    }

    var notifyFeatureFlagsUpdatedCalled = false
    func notifyFeatureFlagsUpdated() {
        notifyFeatureFlagsUpdatedCalled = true
    }

    func notifySplitKilled() {
        notifySplitKilledCalled = true
        splitSynchronizer.notifySplitKilled()
    }

    func start(forKey key: Key) {
        splitSynchronizer.start(forKey: key)
    }

    func loadMySegmentsFromCache(forKey key: String) {
        splitSynchronizer.loadMySegmentsFromCache(forKey: key)
    }

    func loadAttributesFromCache(forKey key: String) {
        splitSynchronizer.loadAttributesFromCache(forKey: key)
    }

    func synchronizeMySegments(forKey key: String) {
        synchronizeMySegmentsCalled = true
        splitSynchronizer.synchronizeMySegments(forKey: key)
    }

    func forceMySegmentsSync(forKey key: String, changeNumbers: SegmentsChangeNumber, delay: Int64) {
        Logger.v("Sync Spy: \(key) - ChangeNumbers(ms: \(changeNumbers.msChangeNumber), mls: \(changeNumbers.mlsChangeNumber), delay: \(delay)")
        splitSynchronizer.forceMySegmentsSync(forKey: key, changeNumbers: changeNumbers, delay: delay)
        forceMySegmentsSyncCalled[key] = true
        forceMySegmentsSyncCount[key]=(forceMySegmentsSyncCount[key] ?? 0) + 1
        forceMySegmentsCalledParams[key] = ForceMySegmentsParams(segmentsCn: changeNumbers, delay: delay)
    }

    func disableSdk() {
        disableSdkCalled = true
    }

    func disableEvents() {
        disableEventsCalled = true
    }

    func disableTelemetry() {
        disableTelemetryCalled = true
    }
}
