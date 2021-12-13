//
//  HttpTelemetryStatsRecorderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Dic-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpTelemetryStatsRecorderTest: XCTestCase {

    var restClient: RestClientStub!
    var recorder: DefaultHttpTelemetryStatsRecorder!
    let telemetryStats = TestingHelper.createTelemetryStats()

    override func setUp() {
        restClient = RestClientStub()
        recorder = DefaultHttpTelemetryStatsRecorder(restClient: restClient)
    }

    func testServerNoReachable() {
        // This recorder doesn't check for connection
        // It should be checked for the worker before pop data
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(telemetryStats)
        } catch {
            isError = true
        }
        XCTAssertFalse(isError)
    }

    func testSuccessSending() throws {

        try recorder.execute(telemetryStats)

        XCTAssertEqual(1, restClient.sendTelemetryStatsCount)
    }

    override func tearDown() {
    }
}

