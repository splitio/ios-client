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
    var loadAttributesFromCacheCalled = false
    var syncAllCalled = false
    var synchronizeSplitsCalled = false
    var synchronizeSplitsChangeNumberCalled = false
    var synchronizeMySegmentsCalled = false
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

    var startPeriodicFetchingExp: XCTestExpectation?
    var stopPeriodicFetchingExp: XCTestExpectation?

    let defaultUserKey: String


    var forceMySegmentsSyncCalled = [String: Bool]()
    var forceMySegmentsSyncCount = [String: Int]()

    init(splitConfig: SplitClientConfig,
         defaultUserKey: String,
         telemetrySynchronizer: TelemetrySynchronizer?,
         byKeyFacade: ByKeyFacade,
         splitApiFacade: SplitApiFacade,
         splitStorageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper,
         eventsSyncHelper: EventsRecorderSyncHelper,
         syncTaskByChangeNumberCatalog: SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>
        = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         splitEventsManager: SplitEventsManager) {

        self.defaultUserKey = defaultUserKey
        self.splitSynchronizer = DefaultSynchronizer(splitConfig: splitConfig,
                                                     defaultUserKey: defaultUserKey,
                                                     telemetrySynchronizer: telemetrySynchronizer,
                                                     byKeyFacade: byKeyFacade,
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

    func forceMySegmentsSync(forKey key: String) {
        splitSynchronizer.forceMySegmentsSync(forKey: key)
        forceMySegmentsSyncCalled[key] = true
        forceMySegmentsSyncCount[key]=(forceMySegmentsSyncCount[key] ?? 0) + 1
    }
}
