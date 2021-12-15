//
//  TelemetrySynchronizerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split



class TelmetrySynchronizerTest: XCTestCase {

    var synchronizer: TelemetrySynchronizer!
    var configRecorderWorker: RecorderWorkerStub!
    var statsRecorderWorker: RecorderWorkerStub!

    override func setUp() {
        configRecorderWorker = RecorderWorkerStub()
        statsRecorderWorker = RecorderWorkerStub()
        synchronizer = DefaultTelemetrySynchronizer(configRecorderWorker: configRecorderWorker,
                                                    statsRecorderWorker: statsRecorderWorker)
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

    override func tearDown() {
    }
}

