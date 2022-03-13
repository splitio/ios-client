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

class SynchronizerSpy: FullSynchronizer {

    var splitSynchronizer: FullSynchronizer

    var loadAndSynchronizeSplitsCalled = false
    var loadMySegmentsFromCacheCalled = false
    var loadAttributesFromCacheCalled = false
    var syncAllCalled = false
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeMySegmentsCalled = false
    var forceMySegmentsSyncCalled = false
    var forceMySegmentsCalledCount = 0
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

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         telemetrySynchronizer: TelemetrySynchronizer?,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         eventsSyncHelper: EventsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
            = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         splitEventsManager: SplitEventsManager) {
        self.splitSynchronizer = DefaultFullSynchronizer(splitConfig: splitConfig,
                                                     telemetrySynchronizer: telemetrySynchronizer,
                                                     splitApiFacade: splitApiFacade,
                                                     splitStorageContainer: splitStorageContainer,
                                                     syncWorkerFactory: syncWorkerFactory,
                                                     impressionsSyncHelper: impressionsSyncHelper,
                                                     eventsSyncHelper: eventsSyncHelper,
                                                     splitsFilterQueryString: splitsFilterQueryString,
                                                     splitEventsManager: splitEventsManager)
    }

    func loadAndSynchronizeSplits() {
        loadAndSynchronizeSplitsCalled = true
        splitSynchronizer.loadAndSynchronizeSplits()
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

    func startPeriodicRecording() {
        startPeriodicRecordingCalled = true
        splitSynchronizer.startPeriodicRecording()
    }

    func stopPeriodicRecording() {
        stopPeriodicRecordingCalled = true
        splitSynchronizer.stopPeriodicRecording()
    }

    func pushEvent(event: EventDTO) {
        pushEventCalled = true
        splitSynchronizer.pushEvent(event: event)
    }

    func pushImpression(impression: KeyImpression) {
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

    func synchronizeSplits() {
        synchronizeSplitsCalled = true
        splitSynchronizer.synchronizeSplits()
        if let exp = syncSplitsExp {
            exp.fulfill()
        }
    }

    func synchronizeSplits(changeNumber: Int64) {
        synchronizeSplitsChangeNumberCalled = true
        splitSynchronizer.synchronizeSplits(changeNumber: changeNumber)
        if let exp = syncSplitsChangeNumberExp {
            exp.fulfill()
        }
    }

    func synchronizeMySegments() {
        synchronizeMySegmentsCalled = true
        splitSynchronizer.synchronizeMySegments()
        if let exp = syncMySegmentsExp {
            exp.fulfill()
        }
    }

    func forceMySegmentsSync() {
        forceMySegmentsSyncCalled = true
        forceMySegmentsCalledCount+=1
        splitSynchronizer.forceMySegmentsSync()
        if let exp = forceMySegmentsSyncExp {
            exp.fulfill()
        }
    }

    func pause() {
        splitSynchronizer.pause()
    }

    func resume() {
        splitSynchronizer.resume()
    }

    func notifiySegmentsUpdated() {
        notifyMySegmentsUpdatedCalled = true
        splitSynchronizer.notifiySegmentsUpdated()
    }

    func notifySplitKilled() {
        notifySplitKilledCalled = true
        splitSynchronizer.notifiySegmentsUpdated()
    }
}
