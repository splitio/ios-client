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

    var splitFetcher: HttpSplitFetcherStub!
    var splitsStorage: SplitsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsUpdateWorker: RetryableSplitsUpdateWorker!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitFetcher.splitChanges = [SplitChange(splits: [], since: 102, till: 102)]
        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [Split](), archivedSplits: [],
                                                  changeNumber: 100, updateTimestamp: 0))
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitsFetcher: splitFetcher,
                                                         splitsStorage: splitsStorage,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         changeNumber: 101,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: backoffCounter,
                                                         splitConfig: SplitClientConfig())

        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsUpdateWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsUpdateWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(1, splitFetcher.fetchCallCount)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
    }

    func testRetryAndSuccess() {
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitsFetcher: splitFetcher,
                                                         splitsStorage: splitsStorage,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         changeNumber: 200,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: backoffCounter,
                                                         splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [nil, nil, change]
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
        XCTAssertEqual(3, splitFetcher.fetchCallCount)
    }

    func testStopNoSuccess() {
        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitsFetcher: splitFetcher,
                                                         splitsStorage: splitsStorage,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         changeNumber: 200,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: backoffCounter,
                                                         splitConfig: SplitClientConfig())

        splitFetcher.splitChanges = [nil]
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
        XCTAssertTrue(1 < splitFetcher.fetchCallCount)
    }

    func testOldChangeNumber() {

        splitsUpdateWorker = RetryableSplitsUpdateWorker(splitsFetcher: splitFetcher,
                                                         splitsStorage: splitsStorage,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         changeNumber: 99,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: backoffCounter,
                                                         splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 100, till: 100)
        splitFetcher.splitChanges = [change]
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
        XCTAssertEqual(0, splitFetcher.fetchCallCount)
    }

    override func tearDown() {
    }

    private func createSplit(name: String) -> Split {
        let split = Split()
        split.name = name
        return split
    }
}
