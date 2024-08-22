//
//  MySegmentsSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsSyncWorkerTest: XCTestCase {

    var mySegmentsFetcher: HttpMySegmentsFetcherStub!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!
    var myLargeSegmentsStorage: ByKeyMySegmentsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var mySegmentsSyncWorker: RetryableMySegmentsSyncWorker!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        myLargeSegmentsStorage = ByKeyMySegmentsStorageStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()

        eventsManager.isSegmentsReadyFired = false

        mySegmentsSyncWorker = RetryableMySegmentsSyncWorker(
            userKey: "CUSTOMER_ID",
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage, 
            myLargeSegmentsStorage: myLargeSegmentsStorage,
            telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: false)
    }

    func testOneTimeFetchSuccess() {
        let msChange = SegmentChange(segments: ["s1", "s2"])
        let mlsChange = SegmentChange(segments: ["s10", "s20"])
        let change = AllSegmentsChange(mySegmentsChange: msChange,
                                       myLargeSegmentsChange: mlsChange)
        mySegmentsFetcher.segments = [change]
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
        XCTAssertEqual(0, mySegmentsFetcher.headerList.count)
    }

    func testRetryAndSuccess() {
        let msChange = SegmentChange(segments: ["s1", "s2"])
        let mlsChange = SegmentChange(segments: ["s1", "s2"])
        let change = AllSegmentsChange(mySegmentsChange: msChange,
                                       myLargeSegmentsChange: mlsChange)
        mySegmentsFetcher.segments = [nil, nil, change]
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

        mySegmentsFetcher.segments = [nil]
        var resultIsSuccess = false
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
            userKey: "CUSTOMER_ID",
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage, 
            myLargeSegmentsStorage: myLargeSegmentsStorage,
            telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: true)

        let msChange = SegmentChange(segments: ["s1", "s2"])
        let mlsChange = SegmentChange(segments: ["s10", "s20"])
        let change = AllSegmentsChange(mySegmentsChange: msChange,
                                       myLargeSegmentsChange: mlsChange)

        mySegmentsFetcher.segments = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        var headers: [String: String]? = nil

        if mySegmentsFetcher.headerList.count > 0 {
            headers = mySegmentsFetcher.headerList[0]
        }
        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSegmentsReadyFired)
        XCTAssertEqual(ServiceConstants.cacheControlNoCache, headers?[ServiceConstants.cacheControlHeader])
    }
}
