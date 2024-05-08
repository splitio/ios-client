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

    var splitFetcher: HttpSplitFetcherStub!
    var splitStorage: SplitsStorageStub!
    var splitChangeProcessor: SplitChangeProcessorStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: RetryableSplitsSyncWorker!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitStorage = SplitsStorageStub()
        splitStorage.changeNumber = 100
        let _ = SplitChange(splits: [], since: splitStorage.changeNumber, till: splitStorage.changeNumber)
        splitChangeProcessor = SplitChangeProcessorStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        var resultIsSuccess = false
        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [change]
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertFalse(splitStorage.clearCalled)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testRetryAndSuccess() {
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [nil, nil, change]
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
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        splitFetcher.splitChanges = [nil]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()
        sleep(3)
        splitsSyncWorker.stop()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertTrue(1 < backoffCounter.retryCallCount)
        XCTAssertFalse(eventsManager.isSplitsReadyFired)
    }

    func testClearExpiredCache() {

        let expiration = 1000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Date().timeIntervalSince1970) - Int64(expiration * 2) // Expired cache
        splitFetcher.splitChanges = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitStorage.clearCalled)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testNoClearNonExpiredCache() {

        let expiration = 1000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 2000,
                                                     defaultQueryString: "",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Date().timeIntervalSince1970) - Int64(expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertFalse(splitStorage.clearCalled)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testChangedQueryString() {
        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "&q=1",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [change]
        splitStorage.splitsFilterQueryString = "&q=2"
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitStorage.clearCalled)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
        XCTAssertEqual("&q=1", splitStorage.splitsFilterQueryString)
    }

    func testNoChangedQueryString() {

        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "&q=1",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [change]
        splitStorage.splitsFilterQueryString = "&q=1"
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitStorage.clearCalled)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
    }

    func testClearExpiredCacheAndChangedQs() {

        let expiration = 1000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "&q=1",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.splitsFilterQueryString = ""
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration * 2) // Expired cache
        splitFetcher.splitChanges = [change]
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitStorage.clearCalled)
        XCTAssertEqual(0, backoffCounter.retryCallCount)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
        XCTAssertEqual("&q=1", splitStorage.splitsFilterQueryString)
    }

    func testUriTooLongError() {

        let expiration = 10000
        splitFetcher.httpError = .uriTooLong
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "&q=1",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [change]
        splitStorage.splitsFilterQueryString = "&q=1"
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")

        var thrownError: HttpError?
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }

        splitsSyncWorker.errorHandler = { error in
            thrownError = error as? HttpError
            exp.fulfill()
        }

        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertEqual(HttpError.uriTooLong, thrownError)
    }

    func testChangedFlagsSpecString() {
        let expiration = 10000
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     cacheExpiration: 100,
                                                     defaultQueryString: "&q=1",
                                                     flagsSpec: "",
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [change]
        splitStorage.splitsFilterQueryString = "&q=1"
        splitStorage.flagsSpec = "1.1"
        var resultIsSuccess = false
        let exp = XCTestExpectation(description: "exp")
        splitsSyncWorker.completion = { success in
            resultIsSuccess = success
            exp.fulfill()
        }
        splitsSyncWorker.start()

        wait(for: [exp], timeout: 3)

        XCTAssertTrue(resultIsSuccess)
        XCTAssertTrue(splitStorage.clearCalled)
        XCTAssertTrue(eventsManager.isSplitsReadyFired)
        XCTAssertEqual("&q=1", splitStorage.splitsFilterQueryString)
        XCTAssertEqual("1.1", splitStorage.flagsSpec)
    }

    private func createSplit(name: String) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: "tt")
        split.isParsed = true
        return split
    }

}
