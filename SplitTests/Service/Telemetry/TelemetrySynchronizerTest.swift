//
//  TelemetrySynchronizerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class TelmetrySynchronizerTest: XCTestCase {
    var synchronizer: TelemetrySynchronizer!
    var configRecorderWorker: RecorderWorkerStub!
    var statsRecorderWorker: RecorderWorkerStub!
    var periodicStatsRecorderWorker: PeriodicRecorderWorkerStub!

    override func setUp() {
        configRecorderWorker = RecorderWorkerStub()
        statsRecorderWorker = RecorderWorkerStub()
        periodicStatsRecorderWorker = PeriodicRecorderWorkerStub()
        synchronizer = DefaultTelemetrySynchronizer(
            configRecorderWorker: configRecorderWorker,
            statsRecorderWorker: statsRecorderWorker,
            periodicStatsRecorderWorker: periodicStatsRecorderWorker)
    }

    func testSyncConfig() {
        configRecorderWorker.expectation = XCTestExpectation()

        synchronizer.synchronizeConfig()

        wait(for: [configRecorderWorker.expectation!], timeout: 5)
        XCTAssertTrue(configRecorderWorker.flushCalled)
        XCTAssertFalse(statsRecorderWorker.flushCalled)
    }

    func testSyncStats() {
        statsRecorderWorker.expectation = XCTestExpectation()

        synchronizer.synchronizeStats()

        wait(for: [statsRecorderWorker.expectation!], timeout: 5)

        XCTAssertTrue(statsRecorderWorker.flushCalled)
        XCTAssertFalse(configRecorderWorker.flushCalled)
    }

    func testStart() {
        synchronizer.start()

        XCTAssertTrue(periodicStatsRecorderWorker.startCalled)
    }

    func testStop() {
        synchronizer.destroy()

        XCTAssertTrue(periodicStatsRecorderWorker.stopCalled)
    }

    override func tearDown() {}
}
