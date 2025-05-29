//
//  PeriodicMySegmentsSyncWorkerTest.swift
//  MySegmentsTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 MySegments. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PeriodicMySegmentsSyncWorkerTest: XCTestCase {
    var mySegmentsStorage: MySegmentsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var mySegmentsSyncWorker: PeriodicMySegmentsSyncWorker!
    let userKey = "CUSTOMER_ID"
    var config: SplitClientConfig!
    var syncHelper: SegmentsSyncHelperMock!

    override func setUp() {
        mySegmentsStorage = MySegmentsStorageStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
        config = SplitClientConfig()
        syncHelper = SegmentsSyncHelperMock()
    }

    func testNormalFetchSdkIsReady() {
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        let msStorage = ByKeyMySegmentsStorageStub()
        let mlsStorage = ByKeyMySegmentsStorageStub()
        syncHelper.results = [TestingHelper.segmentsSyncResult()]
        syncHelper.exp = XCTestExpectation()
        syncHelper.expSyncLimit = 3

        mySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(
            mySegmentsStorage: msStorage,
            myLargeSegmentsStorage: mlsStorage,
            telemetryProducer: TelemetryStorageStub(),
            timer: timer,
            eventsManager: eventsManager,
            syncHelper: syncHelper)
        mySegmentsSyncWorker.start()

        for i in 0 ..< 3 {
            msStorage.changeNumber = 100 + i.asInt64()
            mlsStorage.changeNumber = 200 + i.asInt64()
            timer.timerHandler?()
        }
        wait(for: [syncHelper.exp!], timeout: 5.0)

        XCTAssertEqual(3, syncHelper.syncCallCount)
        XCTAssertEqual(102, syncHelper.lastMsTillParam)
        XCTAssertEqual(202, syncHelper.lastMlsTillParam)
        XCTAssertTrue(eventsManager.isSegmentsReadyFired)
    }

    func testFetchWhenNoSegmentsReadyYet() {
        eventsManager.isSegmentsReadyFired = false
        eventsManager.isSplitsReadyFired = false
        eventsManager.isSdkReadyChecked = false
        let timer = PeriodicTimerStub()
        let msStorage = ByKeyMySegmentsStorageStub()
        let mlsStorage = ByKeyMySegmentsStorageStub()
        syncHelper.results = [TestingHelper.segmentsSyncResult()]

        mySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(
            mySegmentsStorage: msStorage,
            myLargeSegmentsStorage: mlsStorage,
            telemetryProducer: TelemetryStorageStub(),
            timer: timer,
            eventsManager: eventsManager,
            syncHelper: syncHelper)

        mySegmentsSyncWorker.start()
        timer.timerHandler?()
        sleep(1)

        XCTAssertEqual(0, syncHelper.syncCallCount)
        XCTAssertFalse(eventsManager.isSegmentsReadyFired)
        XCTAssertTrue(eventsManager.isSdkReadyChecked)
    }
}
