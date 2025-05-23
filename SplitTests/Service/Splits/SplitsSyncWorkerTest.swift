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
    var generalInfoStorage: GeneralInfoStorageMock!
    var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    var splitChangeProcessor: SplitChangeProcessorStub!
    var ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessorStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: RetryableSplitsSyncWorker!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitStorage = SplitsStorageStub()
        generalInfoStorage = GeneralInfoStorageMock()
        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        splitStorage.changeNumber = 100
        let _ = SplitChange(splits: [], since: splitStorage.changeNumber, till: splitStorage.changeNumber)
        splitChangeProcessor = SplitChangeProcessorStub()
        ruleBasedSegmentChangeProcessor = RuleBasedSegmentChangeProcessorStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     generalInfoStorage: generalInfoStorage,
                                                     ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        var resultIsSuccess = false
        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [TargetingRulesChange(featureFlags: change)]
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
                                                     generalInfoStorage: generalInfoStorage,
                                                     ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [nil, nil, TargetingRulesChange(featureFlags: change)]
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
                                                     generalInfoStorage: generalInfoStorage,
                                                     ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
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

    func testUriTooLongError() {

        let expiration = 10000
        splitFetcher.httpError = .uriTooLong
        splitsSyncWorker = RetryableSplitsSyncWorker(splitFetcher: splitFetcher,
                                                     splitsStorage: splitStorage,
                                                     generalInfoStorage: generalInfoStorage,
                                                     ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                     splitChangeProcessor: splitChangeProcessor,
                                                     ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                     eventsManager: eventsManager,
                                                     reconnectBackoffCounter: backoffCounter,
                                                     splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitStorage.updateTimestamp = Int64(Int(Date().timeIntervalSince1970) - expiration / 2) // Non Expired cache
        splitFetcher.splitChanges = [TargetingRulesChange(featureFlags: change)]
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

    private func createSplit(name: String) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: "tt")
        split.isCompletelyParsed = true
        return split
    }

}
