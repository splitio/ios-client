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

    var splitChangeFetcher: SplitChangeFetcherStub!
    var splitCache: SplitCacheStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var splitsSyncWorker: PeriodicSplitsSyncWorker!

    override func setUp() {
        splitChangeFetcher = SplitChangeFetcherStub()
        splitCache = SplitCacheStub(splits: [Split](), changeNumber: 100)
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testNormalFetch() {
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        splitsSyncWorker = PeriodicSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                    splitCache: splitCache,
                                                    timer: timer,
                                                    eventsManager: eventsManager)

        splitsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }

        sleep(1)
        XCTAssertEqual(5, splitChangeFetcher.fetchCallCount)
    }

    func testNoSdkReadyFetch() {
        eventsManager.isSplitsReadyFired = false
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        splitsSyncWorker = PeriodicSplitsSyncWorker(splitChangeFetcher: splitChangeFetcher,
                                                    splitCache: splitCache,
                                                    timer: timer,
                                                    eventsManager: eventsManager)

        splitsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }

        XCTAssertEqual(0, splitChangeFetcher.fetchCallCount)
    }

    private func createSplit(name: String) -> Split {
        let split = Split()
        split.name = name
        return split
    }

}
