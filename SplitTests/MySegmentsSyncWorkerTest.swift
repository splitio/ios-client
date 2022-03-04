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
    var mySegmentsStorage: OneKeyMySegmentsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var mySegmentsSyncWorker: RetryableMySegmentsSyncWorker!

    override func setUp() {
        mySegmentsFetcher = HttpMySegmentsFetcherStub()
        mySegmentsStorage = OneKeyMySegmentsStorageStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()

        eventsManager.isSegmentsReadyFired = false

        mySegmentsSyncWorker = RetryableMySegmentsSyncWorker(
            userKey: "CUSTOMER_ID",
            mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: mySegmentsStorage, telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: false)
    }

    func testOneTimeFetchSuccess() {

        mySegmentsFetcher.allSegments = [["s1", "s2"]]
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

        mySegmentsFetcher.allSegments = [nil, nil, ["s1", "s2"]]
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

        mySegmentsFetcher.allSegments = [nil]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        mySegmentsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        mySegmentsSyncWorker.start()
        sleep(1)
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
            mySegmentsStorage: mySegmentsStorage, telemetryProducer: TelemetryStorageStub(),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            avoidCache: true)

        mySegmentsFetcher.allSegments = [["s1", "s2"]]
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

    override func tearDown() {
    }
}
