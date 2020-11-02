//
//  PeriodicMySegmentsSyncWorkerTest.swift
//  MySegmentsTests
//
//  Created by Javier L. Avrudsky on 16/09/2020.
//  Copyright © 2020 MySegments. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PeriodicMySegmentsSyncWorkerTest: XCTestCase {

    var mySegmentsChangeFetcher: MySegmentsChangeFetcherStub!
    var mySegmentsCache: MySegmentsCacheStub!
    var eventsManager: SplitEventsManagerMock!
    var backoffCounter: ReconnectBackoffCounterStub!
    var mySegmentsSyncWorker: PeriodicMySegmentsSyncWorker!
    let userKey = "CUSTOMER_ID"

    override func setUp() {
        mySegmentsChangeFetcher = MySegmentsChangeFetcherStub()
        mySegmentsCache = MySegmentsCacheStub()
        eventsManager = SplitEventsManagerMock()
        backoffCounter = ReconnectBackoffCounterStub()
        eventsManager.isSplitsReadyFired = false
    }

    func testNormalFetch() {
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        mySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(userKey: userKey,
                                                            mySegmentsFetcher: mySegmentsChangeFetcher,
                                                            mySegmentsCache: mySegmentsCache,
                                                            timer: timer,
                                                            eventsManager: eventsManager)

        mySegmentsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }
        sleep(1)

        XCTAssertEqual(5, mySegmentsChangeFetcher.fetchMySegmentsCount)
    }

    func testNoSdkReadyFetch() {
        eventsManager.isSplitsReadyFired = false
        eventsManager.isSegmentsReadyFired = true
        let timer = PeriodicTimerStub()
        mySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(userKey: userKey,
                                                            mySegmentsFetcher: mySegmentsChangeFetcher,
                                                            mySegmentsCache: mySegmentsCache,
                                                            timer: timer,
                                                            eventsManager: eventsManager)

        mySegmentsSyncWorker.start()

        for _ in 0..<5 {
            timer.timerHandler?()
        }

        XCTAssertEqual(0, mySegmentsChangeFetcher.fetchMySegmentsCount)
    }
}
