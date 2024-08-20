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
    var eventsManager: SplitEventsManagerMock!
    var eventsManager: SplitEventsManager!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: PeriodicSplitsSyncWorker!
    var splitChangeProcessor: SplitChangeProcessorStub!

    override func setUp() {
        splitFetcher = HttpSplitFetcherStub()
        splitsStorage = SplitsStorageStub()
        splitChangeProcessor = SplitChangeProcessorStub()
        eventsManager = SplitEventsManagerMock()
        eventsManager = SplitsEventsManagerWrapper(eventsManager)
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testNormalFetch() {
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        splitsSyncWorker = PeriodicSplitsSyncWorker(splitFetcher: splitFetcher,
                                                    splitsStorage: splitsStorage,
                                                    splitChangeProcessor: splitChangeProcessor,
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
                                                    splitChangeProcessor: splitChangeProcessor,
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
        split.isParsed = true
        return split
    }

}
