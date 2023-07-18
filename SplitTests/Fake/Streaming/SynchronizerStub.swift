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

class SynchronizerStub: Synchronizer {

    var loadAndSynchronizeSplitsCalled = false
    var loadMySegmentsFromCacheCalled = false
    var loadAttributesFromCacheCalled = false
    var syncAllCalled = false
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeMySegmentsCalled = false
    var forceMySegmentsSyncCalled = false
    var startPeriodicFetchingCalled = false
    var stopPeriodicFetchingCalled = false
    var startRecordingTelemetryCalled = false
    var stopRecordingTelemetryCalled = false
    var startRecordingUserDataCalled = false
    var stopRecordingUserDataCalled = false
    var pushEventCalled = false
    var pushImpressionCalled = false
    var flushCalled = false
    var destroyCalled = false

    var notifyMySegmentsUpdatedCalled = false
    var notifySplitKilledCalled = false

    var syncSplitsExp: XCTestExpectation?
    var syncSplitsChangeNumberExp: XCTestExpectation?
    var syncMySegmentsExp: XCTestExpectation?
    var forceMySegmentsSyncExp = [String: XCTestExpectation]()
    var notifyMySegmentsUpdatedExp = [String: XCTestExpectation]()

    var startPeriodicFetchingExp: XCTestExpectation?
    var stopPeriodicFetchingExp: XCTestExpectation?

    var syncTelemetryConfig = false

    var pauseCalled = false
    var resumeCalled = false

    func loadAndSynchronizeSplits() {
        loadAndSynchronizeSplitsCalled = true
    }

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCacheCalled = true
    }

    func loadAttributesFromCache() {
        loadAttributesFromCacheCalled = true
    }

    var startForKeyCalled = [Key: Bool]()
    func start(forKey key: Key) {
        startForKeyCalled[key] = true
    }

    var loadMySegmentsFromCacheForKeyCalled = [String: Bool]()
    func loadMySegmentsFromCache(forKey key: String) {
        loadMySegmentsFromCacheForKeyCalled[key] = true
    }

    var loadAttributesFromCacheForKeyCalled = [String: Bool]()
    func loadAttributesFromCache(forKey key: String) {
        loadAttributesFromCacheForKeyCalled[key] = true
    }

    var synchronizeMySegmentsForKeyCalled = [String: Bool]()
    func synchronizeMySegments(forKey key: String) {
        synchronizeMySegmentsForKeyCalled[key] = true
    }

    var forceMySegmentsSyncForKeyCalled = [String: Bool]()
    func forceMySegmentsSync(forKey key: String) {
        forceMySegmentsSyncForKeyCalled[key] = true

        if let exp = forceMySegmentsSyncExp[key] {
            exp.fulfill()
        }
    }

    var notifySegmentsUpdatedForKeyCalled = [String: Bool]()
    func notifySegmentsUpdated(forKey key: String) {
        notifySegmentsUpdatedForKeyCalled[key] = true
        if let exp = notifyMySegmentsUpdatedExp[key] {
            exp.fulfill()
        }
    }

    func syncAll() {
        syncAllCalled = true
    }

    func synchronizeTelemetryConfig() {
        syncTelemetryConfig = true
    }

    func startPeriodicFetching() {
        startPeriodicFetchingCalled = true
        if let exp = startPeriodicFetchingExp {
            exp.fulfill()
        }
    }

    func stopPeriodicFetching() {
        stopPeriodicFetchingCalled = true
        if let exp = stopPeriodicFetchingExp {
            exp.fulfill()
        }
    }

    func startRecordingUserData() {
        startRecordingUserDataCalled = true
    }

    func stopRecordingUserData() {
        stopRecordingUserDataCalled = true
    }

    func startRecordingTelemetry() {
        startRecordingTelemetryCalled = true
    }

    func stopRecordingTelemetry() {
        stopRecordingTelemetryCalled = true
    }

    func pushEvent(event: EventDTO) {
        pushEventCalled = true
    }

    func pushImpression(impression: KeyImpression) {
        pushImpressionCalled = true
    }

    func flush() {
        flushCalled = true
    }

    func destroy() {
        destroyCalled = true
    }

    func synchronizeSplits() {
        synchronizeSplitsCalled = true
        if let exp = syncSplitsExp {
            exp.fulfill()
        }
    }

    func synchronizeSplits(changeNumber: Int64) {
        synchronizeSplitsChangeNumberCalled = true
        if let exp = syncSplitsChangeNumberExp {
            exp.fulfill()
        }
    }

    func synchronizeMySegments() {
        synchronizeMySegmentsCalled = true
        if let exp = syncMySegmentsExp {
            exp.fulfill()
        }
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func notifiySegmentsUpdated() {
        notifyMySegmentsUpdatedCalled = true
    }

    var notifyFeatureFlagsUpdatedCalled = true
    func notifyFeatureFlagsUpdated() {
        notifyFeatureFlagsUpdatedCalled = true
    }

    func notifySplitKilled() {
        notifySplitKilledCalled = true
    }
}
