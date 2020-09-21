//
//  SynchronizerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SynchronizerTest: XCTestCase {

    var splitsFetcher: SplitChangeFetcher!
    var impressionsManager: ImpressionsManagerStub!
    var trackManager: TrackManagerStub!
    var splitsSyncWorker: RetryableSyncWorkerStub!
    var mySegmentsSyncWorker: RetryableSyncWorkerStub!
    var periodicSplitsSyncWorker: PeriodicSyncWorkerStub!
    var periodicMySegmentsSyncWorker: PeriodicSyncWorkerStub!

    var splitsCache: SplitCacheProtocol!
    var mySegmentsCache: MySegmentsCacheProtocol!

    var updateWorkerCatalog = SyncDictionarySingleWrapper<Int64, RetryableSyncWorker>()
    var syncWorkerFactory = SyncWorkerFactoryStub()

    var synchronizer: Synchronizer!

    override func setUp() {
        splitsFetcher = SplitChangeFetcherStub()
        impressionsManager = ImpressionsManagerStub()
        trackManager = TrackManagerStub()
        splitsSyncWorker = RetryableSyncWorkerStub()
        mySegmentsSyncWorker = RetryableSyncWorkerStub()
        periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
        periodicMySegmentsSyncWorker = PeriodicSyncWorkerStub()

        splitsCache = SplitCacheStub(splits: [], changeNumber: 100)
        mySegmentsCache = MySegmentsCacheStub()

        let apiFacade = SplitApiFacade(splitsFetcher: splitsFetcher, impressionsManager: impressionsManager,
                                       trackManager: trackManager, splitsSyncWorker: splitsSyncWorker,
                                       mySegmentsSyncWorker: mySegmentsSyncWorker,
                                       periodicSplitsSyncWorker: periodicSplitsSyncWorker,
                                       periodicMySegmentsSyncWorker: periodicMySegmentsSyncWorker)
        let storageContainer = SplitStorageContainer(splitsCache: splitsCache, mySegmentsCache: mySegmentsCache)

        synchronizer = DefaultSynchronizer(splitApiFacade: apiFacade,
                                           splitStorageContainer: storageContainer,
                                           syncWorkerFactory: syncWorkerFactory,
                                           syncTaskByChangeNumberCatalog: updateWorkerCatalog)
    }

    func testRunInitialSync() {

        synchronizer.runInitialSynchronization()

        XCTAssertTrue(splitsSyncWorker.startCalled)
        XCTAssertTrue(mySegmentsSyncWorker.startCalled)
    }

    func testSynchronizeSplits() {

        synchronizer.synchronizeSplits()

        XCTAssertTrue(splitsSyncWorker.startCalled)
    }

    func testSynchronizeMySegments() {

        synchronizer.synchronizeMySegments()

        XCTAssertTrue(mySegmentsSyncWorker.startCalled)
    }

    func testSynchronizeSplitsWithChangeNumber() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        let initialSyncCount = updateWorkerCatalog.count
        sw1.completion?(true)
        let oneCompletedSyncCount = updateWorkerCatalog.count
        sw2.completion?(true)

        XCTAssertEqual(2, initialSyncCount)
        XCTAssertEqual(1, oneCompletedSyncCount)
        XCTAssertEqual(0, updateWorkerCatalog.count)

        XCTAssertFalse(sw1.stopCalled)
        XCTAssertFalse(sw2.stopCalled)
    }

    func testStartPeriodicFetching() {

        synchronizer.startPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.startCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.startCalled)
    }

    func testStopPeriodicFetching() {

        synchronizer.stopPeriodicFetching()

        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
    }

    func testStartPeriodicRecording() {

        synchronizer.startPeriodicRecording()

        XCTAssertTrue(impressionsManager.startCalled)
        XCTAssertTrue(trackManager.startCalled)
    }

    func testStopPeriodicRecording() {

        synchronizer.stopPeriodicRecording()

        XCTAssertTrue(impressionsManager.stopCalled)
        XCTAssertTrue(trackManager.stopCalled)
    }

    func testFlush() {

        synchronizer.flush()

        XCTAssertTrue(impressionsManager.flushCalled)
        XCTAssertTrue(trackManager.flushCalled)
    }

    func testDestroy() {

        let sw1 = RetryableSyncWorkerStub()
        let sw2 = RetryableSyncWorkerStub()

        syncWorkerFactory.retryableSplitsUpdateWorkers = [sw1, sw2]
        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        synchronizer.destroy()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(mySegmentsSyncWorker.stopCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
        XCTAssertTrue(sw1.stopCalled)
        XCTAssertTrue(sw2.stopCalled)
        XCTAssertEqual(0, updateWorkerCatalog.count)
    }

    override func tearDown() {
    }
}
