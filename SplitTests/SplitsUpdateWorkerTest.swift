//
//  SplitsUpdateWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitsUpdateWorkerTest: XCTestCase {

    var splitChangeFetcher: SplitChangeFetcherStub!
    var splitCache: SplitCacheStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsUpdateWorker: RetryableSplitsUpdateWorker!

    override func setUp() {
        splitChangeFetcher = SplitChangeFetcherStub()
        splitCache = SplitCacheStub(splits: [Split](), changeNumber: 100)
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitChangeFetcher: splitChangeFetcher,
                                                         splitCache: splitCache,
                                                         changeNumber: 101,
                                                         reconnectBackoffCounter: backoffCounter)

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsUpdateWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsUpdateWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(1, splitChangeFetcher.fetchCallCount)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
    }

    func testRetryAndSuccess() {
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitChangeFetcher: splitChangeFetcher,
                                                         splitCache: splitCache,
                                                         changeNumber: 100,
                                                         reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitChangeFetcher.changes = [nil, nil, change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsUpdateWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsUpdateWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(2, backoffCounter.retryCallCount)
        XCTAssertEqual(3, splitChangeFetcher.fetchCallCount)
    }

    func testStopNoSuccess() {
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitChangeFetcher: splitChangeFetcher,
                                                         splitCache: splitCache,
                                                         changeNumber: 100,
                                                         reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitChangeFetcher.changes = [nil]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsUpdateWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsUpdateWorker.start()
        sleep(1)
        splitsUpdateWorker.stop()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertTrue(1 < backoffCounter.retryCallCount)
        XCTAssertTrue(1 < splitChangeFetcher.fetchCallCount)
    }

    func testOldChangeNumber() {

        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitChangeFetcher: splitChangeFetcher,
                                                         splitCache: splitCache,
                                                         changeNumber: 100,
                                                         reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.setChangeNumber(1000)
        splitChangeFetcher.changes = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsUpdateWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsUpdateWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertEqual(0, splitChangeFetcher.fetchCallCount)
    }

    override func tearDown() {
    }

    private func createSplit(name: String) -> Split {
        let split = Split()
        split.name = name
        return split
    }
}
