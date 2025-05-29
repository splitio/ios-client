//
//  MySegmentsSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class MySegmentsSyncWorkerTest: XCTestCase {
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!
    var myLargeSegmentsStorage: ByKeyMySegmentsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var mySegmentsSyncWorker: RetryableMySegmentsSyncWorker!
    var changeNumbers: SegmentsChangeNumber!
    var syncHelper: SegmentsSyncHelperMock!

    override func setUp() {
        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        myLargeSegmentsStorage = ByKeyMySegmentsStorageStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()

        eventsManager.isSegmentsReadyFired = false
        changeNumbers = SegmentsChangeNumber(msChangeNumber: -1, mlsChangeNumber: 100)
        syncHelper = SegmentsSyncHelperMock()

        mySegmentsSyncWorker = RetryableMySegmentsSyncWorker(
            telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: false,
            changeNumbers: changeNumbers,
            syncHelper: syncHelper)
    }

    func testOneTimeFetchSuccess() {
        syncHelper.results = [TestingHelper.segmentsSyncResult()]

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSegmentsReadyFired)
        XCTAssertEqual(0, syncHelper.lastHeadersParam?.count ?? 0)
    }

    func testRetryAndSuccess() {
        syncHelper.results = [
            TestingHelper.segmentsSyncResult(false),
            TestingHelper.segmentsSyncResult(false),
            TestingHelper.segmentsSyncResult(false),
            TestingHelper.segmentsSyncResult(true),
        ]

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(2, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSegmentsReadyFired)
    }

    func testStopNoSuccess() {
        var resultIsSuccess = false
        syncHelper.results = [TestingHelper.segmentsSyncResult(false)]
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()
        sleep(3)
        mySegmentsSyncWorker.stop()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertTrue(1 < backoffCounter.retryCallCount)
        XCTAssertFalse(eventsManager.isSegmentsReadyFired)
    }

    func testNoCacheHeader() {
        mySegmentsSyncWorker = RetryableMySegmentsSyncWorker(
            telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: true,
            changeNumbers: changeNumbers(mlsChangeNumber: 100),
            syncHelper: syncHelper)

        syncHelper.results = [TestingHelper.segmentsSyncResult()]

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSegmentsReadyFired)
        XCTAssertEqual(
            ServiceConstants.cacheControlNoCache,
            syncHelper.lastHeadersParam?[ServiceConstants.cacheControlHeader])
    }

    func changeNumbers(_ msChangeNumber: Int64 = -1, mlsChangeNumber: Int64) -> SegmentsChangeNumber {
        return SegmentsChangeNumber(msChangeNumber: msChangeNumber, mlsChangeNumber: mlsChangeNumber)
    }
}
