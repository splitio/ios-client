//
//  PeriodicSplitsSyncWorkerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PeriodicSplitsSyncWorkerTest: XCTestCase {

    var splitFetcher: HttpSplitFetcherStub!
    var splitsStorage: SplitsStorageStub!
    var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    var generalInfoStorage: GeneralInfoStorageMock!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: PeriodicSplitsSyncWorker!
    var splitChangeProcessor: SplitChangeProcessorStub!
    var ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessorStub!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitsStorage = SplitsStorageStub()
        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        generalInfoStorage = GeneralInfoStorageMock()
        splitChangeProcessor = SplitChangeProcessorStub()
        ruleBasedSegmentChangeProcessor = RuleBasedSegmentChangeProcessorStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testNormalFetch() {
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        splitsSyncWorker = PeriodicSplitsSyncWorker(splitFetcher: splitFetcher,
                                                    splitsStorage: splitsStorage,
                                                    generalInfoStorage: generalInfoStorage,
                                                    ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                    splitChangeProcessor: splitChangeProcessor,
                                                    ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                    timer: timer,
                                                    eventsManager: eventsManager,
                                                    splitConfig: SplitClientConfig())

        splitsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }

        sleep(1)
        XCTAssertEqual(5, splitFetcher.fetchCallCount)
    }

    func testNoSdkReadyFetch() {
        eventsManager.isSplitsReadyFired = false
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        splitsSyncWorker = PeriodicSplitsSyncWorker(splitFetcher: splitFetcher,
                                                    splitsStorage: splitsStorage,
                                                    generalInfoStorage: generalInfoStorage,
                                                    ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                                    splitChangeProcessor: splitChangeProcessor,
                                                    ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                                                    timer: timer,
                                                    eventsManager: eventsManager,
                                                    splitConfig: SplitClientConfig())

        splitsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }

        XCTAssertEqual(0, splitFetcher.fetchCallCount)
    }

    private func createSplit(name: String) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: "tt")
        split.isCompletelyParsed = true
        return split
    }

}
