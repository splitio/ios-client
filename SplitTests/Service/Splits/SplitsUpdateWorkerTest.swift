//
//  SplitsUpdateWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SplitsUpdateWorkerTest: XCTestCase {
    var splitFetcher: HttpSplitFetcherStub!
    var splitsStorage: SplitsStorageStub!
    var generalInfoStorage: GeneralInfoStorageMock!
    var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsUpdateWorker: RetryableSplitsUpdateWorker!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitFetcher.splitChanges = [
            TargetingRulesChange(featureFlags: SplitChange(splits: [], since: 102, till: 102)),
        ]
        splitsStorage = SplitsStorageStub()
        generalInfoStorage = GeneralInfoStorageMock()
        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(
            activeSplits: [Split](),
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 0))
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testOneTimeFetchSuccess() {
        // Cache expiration timestamp set to 0 (no clearing cache)
        splitsUpdateWorker = RetryableSplitsUpdateWorker(
            splitsFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            generalInfoStorage: generalInfoStorage,
            splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
            ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            changeNumber: SplitsUpdateChangeNumber(flags: 101, rbs: nil),
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
        splitsUpdateWorker = RetryableSplitsUpdateWorker(
            splitsFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            generalInfoStorage: generalInfoStorage,
            splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
            ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            changeNumber: SplitsUpdateChangeNumber(flags: 200, rbs: nil),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 200, till: 200)
        splitFetcher.splitChanges = [nil, nil, TargetingRulesChange(featureFlags: change)]
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
        splitsUpdateWorker = RetryableSplitsUpdateWorker(
            splitsFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            generalInfoStorage: generalInfoStorage,
            splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
            ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            changeNumber: SplitsUpdateChangeNumber(flags: 200, rbs: nil),
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
        sleep(3)
        splitsUpdateWorker.stop()

        wait(for: [exp], timeout: 3)

        XCTAssertFalse(resultIsSuccess)
        XCTAssertTrue(1 < backoffCounter.retryCallCount)
        XCTAssertTrue(1 < splitFetcher.fetchCallCount)
    }

    func testOldChangeNumber() {
        splitsUpdateWorker = RetryableSplitsUpdateWorker(
            splitsFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
            generalInfoStorage: generalInfoStorage,
            splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
            ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            changeNumber: SplitsUpdateChangeNumber(flags: 99, rbs: nil),
            eventsManager: eventsManager,
            reconnectBackoffCounter: backoffCounter,
            splitConfig: SplitClientConfig())

        let change = SplitChange(splits: [], since: 100, till: 100)
        splitFetcher.splitChanges = [TargetingRulesChange(featureFlags: change)]
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

    override func tearDown() {}

    private func createSplit(name: String) -> Split {
        return Split(name: name, trafficType: "user", status: .active, sets: nil, json: "")
    }
}
