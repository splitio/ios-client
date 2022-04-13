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
    var startPeriodicRecordingCalled = false
    var stopPeriodicRecordingCalled = false
    var pushEventCalled = false
    var pushImpressionCalled = false
    var flushCalled = false
    var destroyCalled = false

    var notifyMySegmentsUpdatedCalled = false
    var notifySplitKilledCalled = false

    var syncSplitsExp: XCTestExpectation?
    var syncSplitsChangeNumberExp: XCTestExpectation?
    var syncMySegmentsExp: XCTestExpectation?
    var forceMySegmentsSyncExp: XCTestExpectation?

    var startPeriodicFetchingExp: XCTestExpectation?
    var stopPeriodicFetchingExp: XCTestExpectation?

    var syncTelemetryConfig = false

    func loadAndSynchronizeSplits() {
        loadAndSynchronizeSplitsCalled = true
    }

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCacheCalled = true
    }

    func loadAttributesFromCache() {
        loadAttributesFromCacheCalled = true
    }

    var startForKeyCalled = false
    func start(forKey key: String) {
        startForKeyCalled = true
    }

    var loadMySegmentsFromCacheForKeyCalled = false
    func loadMySegmentsFromCache(forKey key: String) {
        loadMySegmentsFromCacheCalled = true
    }

    var loadAttributesFromCacheForKeyCalled = false
    func loadAttributesFromCache(forKey key: String) {
        loadAttributesFromCacheForKeyCalled = true
    }

    var synchronizeMySegmentsForKeyCalled = true
    func synchronizeMySegments(forKey key: String) {
        synchronizeMySegmentsForKeyCalled = true
    }

    var forceMySegmentsSyncForKeyCalled = false
    func forceMySegmentsSync(forKey key: String) {
        forceMySegmentsSyncForKeyCalled = true
    }

    var notifySegmentsUpdatedForKey = false
    func notifySegmentsUpdated(forKey: String) {
        notifySegmentsUpdatedForKey = true
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

    func startPeriodicRecording() {
        startPeriodicRecordingCalled = true
    }

    func stopPeriodicRecording() {
        stopPeriodicRecordingCalled = true
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

    func forceMySegmentsSync() {
        forceMySegmentsSyncCalled = true
        if let exp = forceMySegmentsSyncExp {
            exp.fulfill()
        }
    }

    func pause() {
    }

    func resume() {
    }

    func notifiySegmentsUpdated() {
        notifyMySegmentsUpdatedCalled = true
    }

    func notifySplitKilled() {
        notifySplitKilledCalled = true
    }
}
