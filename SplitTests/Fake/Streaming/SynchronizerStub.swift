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
    var syncAllCalled = false
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeMySegmentsCalled = false
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

    func loadAndSynchronizeSplits() {
        loadAndSynchronizeSplitsCalled = true
    }

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCacheCalled = true
    }

    func syncAll() {
        syncAllCalled = true
    }

    func startPeriodicFetching() {
        startPeriodicFetchingCalled = true
    }

    func stopPeriodicFetching() {
        stopPeriodicFetchingCalled = true
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

    func pushImpression(impression: Impression) {
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
