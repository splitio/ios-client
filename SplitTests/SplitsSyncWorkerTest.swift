//
//  SplitsSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitsSyncWorkerTest: XCTestCase {

    var splitChangeFetcher: SplitChangeFetcherStub!
    var splitCache: SplitCacheStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: RetryableSplitsSyncWorker!

    override func setUp() {
        splitChangeFetcher = SplitChangeFetcherStub()
        splitCache = SplitCacheStub(splits: [Split](), changeNumber: 100)
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertFalse(splitChangeFetcher.clearCacheParams.last ?? true)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testRetryAndSuccess() {
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitChangeFetcher.changes = [nil, nil, change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(2, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testStopNoSuccess() {
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitChangeFetcher.changes = [nil]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()
        sleep(1)
        splitsSyncWorker.stop()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertTrue(1 < backoffCounter.retryCallCount)
        XCTAssertFalse(eventsManager.isSplitsReadyFired)
    }

    func testClearExpiredCache() {

        let expiration = 1000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: expiration,
                                                     defaultQueryString: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration * 2 // Expired cache
        splitChangeFetcher.changes = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitChangeFetcher.clearCacheParams.last ?? false)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testNoClearNonExpiredCache() {

        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: expiration,
                                                     defaultQueryString: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration / 2 // Non Expired cache
        splitChangeFetcher.changes = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertFalse(splitChangeFetcher.clearCacheParams.last ?? true)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testChangedQueryString() {

        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: expiration,
                                                     defaultQueryString: "&q=1",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration / 2 // Non Expired cache
        splitChangeFetcher.changes = [change]
        splitCache.setQueryString("&q=2")
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitChangeFetcher.clearCacheParams.last ?? false)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
        XCTAssertEqual("&q=1", splitCache.getQueryString())
    }

    func testNoChangedQueryString() {

        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: expiration,
                                                     defaultQueryString: "&q=1",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration / 2 // Non Expired cache
        splitChangeFetcher.changes = [change]
        splitCache.setQueryString("&q=1")
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertFalse(splitChangeFetcher.clearCacheParams.last ?? true)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testClearExpiredCacheAndChangedQs() {

        let expiration = 1000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                     splitCache: splitCache,
                                                     cacheExpiration: expiration,
                                                     defaultQueryString: "&q=1",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter)

        let change = SplitChange()
        change.splits = []
        change.since = 100
        change.till = 200
        splitCache.setQueryString("")
        splitCache.timestamp = Int(Date().timeIntervalSince1970) - expiration * 2 // Expired cache
        splitChangeFetcher.changes = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitChangeFetcher.clearCacheParams.last ?? false)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
        XCTAssertEqual("&q=1", splitCache.getQueryString())
    }

    override func tearDown() {
    }

    private func createSplit(name: String) -> Split {
        let split = Split()
        split.name = name
        return split
    }

}
