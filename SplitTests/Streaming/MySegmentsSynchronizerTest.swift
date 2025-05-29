//
//  MySegmentsSynchronizerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class MySegmentsSynchronizerTest: XCTestCase {
    var mySegmentsSync: MySegmentsSynchronizer!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!
    var myLargeSegmentsStorage: ByKeyMySegmentsStorageStub!
    var syncWorkerFactory: MySegmentsSyncWorkerFactoryStub!
    var eventsManager: SplitEventsManagerStub!
    let userKey = "CUSTOMER_ID"
    var mySegmentsSyncWorker: RetryableMySegmentsSyncWorkerStub!
    var mySegmentsForceWorker: RetryableMySegmentsSyncWorkerStub!
    var periodicMySegmentsSyncWorker: PeriodicSyncWorkerStub!
    var timerManager: TimersManagerMock!

    override func setUp() {
        mySegmentsSyncWorker = RetryableMySegmentsSyncWorkerStub(userKey: userKey, avoidCache: false)
        mySegmentsForceWorker = RetryableMySegmentsSyncWorkerStub(userKey: userKey, avoidCache: true)
        periodicMySegmentsSyncWorker = PeriodicSyncWorkerStub()
        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        myLargeSegmentsStorage = ByKeyMySegmentsStorageStub()
        syncWorkerFactory = MySegmentsSyncWorkerFactoryStub()
        eventsManager = SplitEventsManagerStub()
        syncWorkerFactory.addMySegmentWorker(mySegmentsSyncWorker, forKey: userKey, avoidCache: false)
        syncWorkerFactory.addMySegmentWorker(mySegmentsForceWorker, forKey: userKey, avoidCache: true)
        syncWorkerFactory.periodicMySegmentsSyncWorker = periodicMySegmentsSyncWorker
        timerManager = TimersManagerMock()

        mySegmentsSync = DefaultMySegmentsSynchronizer(
            userKey: userKey,
            splitConfig: SplitClientConfig(),
            mySegmentsStorage: mySegmentsStorage,
            myLargeSegmentsStorage: myLargeSegmentsStorage,
            syncWorkerFactory: syncWorkerFactory,
            eventsManager: eventsManager,
            timerManager: timerManager)
    }

    func testLoadMySegmentsFromCache() {
        let exp = XCTestExpectation()
        eventsManager.mySegmentsLoadedEventExp = exp
        mySegmentsSync.loadMySegmentsFromCache()

        wait(for: [exp], timeout: 5.0)

        XCTAssertTrue(mySegmentsStorage.loadLocalCalled)
        XCTAssertEqual(1, eventsManager.mySegmentsLoadedEventFiredCount)
    }

    func testSynchronize() {
        mySegmentsSync.synchronizeMySegments()

        XCTAssertTrue(mySegmentsSyncWorker.startCalled)
        XCTAssertFalse(mySegmentsForceWorker.startCalled)
    }

    func testForceSync() {
        let changeNumbers = SegmentsChangeNumber(msChangeNumber: 10, mlsChangeNumber: 100)
        let delay: Int64 = 1

        mySegmentsSync.forceMySegmentsSync(
            changeNumbers: changeNumbers,
            delay: delay)
        XCTAssertTrue(timerManager.timerIsAdded(timer: .syncSegments))
    }

    func testForceSyncNoDelay() {
        let changeNumbers = SegmentsChangeNumber(msChangeNumber: 10, mlsChangeNumber: 100)
        let delay: Int64 = 0
        let exp = XCTestExpectation()

        mySegmentsForceWorker.startExp = exp

        mySegmentsSync.forceMySegmentsSync(
            changeNumbers: changeNumbers,
            delay: delay)

        wait(for: [exp], timeout: 5.0)
        XCTAssertFalse(timerManager.timerIsAdded(timer: .syncSegments))
        XCTAssertTrue(mySegmentsForceWorker.startCalled)
    }

    func testNoPeriodicSync() {
        XCTAssertFalse(periodicMySegmentsSyncWorker.startCalled)
        XCTAssertFalse(periodicMySegmentsSyncWorker.stopCalled)
    }

    func testPeriodicStartStop() {
        mySegmentsSync.startPeriodicFetching()
        mySegmentsSync.stopPeriodicFetching()

        XCTAssertTrue(periodicMySegmentsSyncWorker.startCalled)
        XCTAssertFalse(periodicMySegmentsSyncWorker.pauseCalled)
        XCTAssertFalse(periodicMySegmentsSyncWorker.resumeCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
    }

    func testPeriodicStartPauseResumeStop() {
        mySegmentsSync.startPeriodicFetching()
        mySegmentsSync.pause()
        mySegmentsSync.resume()
        mySegmentsSync.stopPeriodicFetching()

        XCTAssertTrue(periodicMySegmentsSyncWorker.startCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.pauseCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.resumeCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
    }

    func testDestroy() {
        mySegmentsSync.startPeriodicFetching()
        mySegmentsSync.destroy()

        XCTAssertTrue(periodicMySegmentsSyncWorker.startCalled)
        XCTAssertTrue(periodicMySegmentsSyncWorker.stopCalled)
    }
}
