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

        synchronizer = DefaultSynchronizer(splitApiFacade: apiFacade, splitStorageContainer: storageContainer)
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

        synchronizer.synchronizeSplits(changeNumber: 100)

        // TODO
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
        synchronizer.destroy()

        XCTAssertTrue(splitsSyncWorker.stopCalled)
        XCTAssertTrue(mySegmentsSyncWorker.stopCalled)
        XCTAssertTrue(periodicSplitsSyncWorker.stopCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
//        let updateTasks = syncTasksByChangeNumber.takeAll()
//        for task in updateTasks.values {
//            task.stop()
//        }
    }

    override func tearDown() {
    }
}
