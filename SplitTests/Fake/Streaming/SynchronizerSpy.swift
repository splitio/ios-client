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

    init(splitConfig: SplitClientConfig,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         eventsSyncHelper: EventsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
            = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         splitEventsManager: SplitEventsManager) {
        self.splitSynchronizer = DefaultSynchronizer(splitConfig: splitConfig, splitApiFacade: splitApiFacade,
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

    func syncAll() {
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
