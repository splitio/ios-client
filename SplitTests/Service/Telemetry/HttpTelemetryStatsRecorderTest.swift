//
//  HttpTelemetryStatsRecorderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Dic-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpTelemetryStatsRecorderTest: XCTestCase {
    var restClient: RestClientStub!
    var recorder: DefaultHttpTelemetryStatsRecorder!
    let telemetryStats = TestingHelper.createTelemetryStats()
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        recorder = DefaultHttpTelemetryStatsRecorder(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        // This recorder doesn't check for connection
        // It should be checked for the worker before pop data
        // by using isEndpointAvailable()
        restClient.isServerAvailable = false

        let isAvailable = recorder.isEndpointAvailable()
        XCTAssertFalse(isAvailable)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessSending() throws {
        try recorder.execute(telemetryStats)

        XCTAssertEqual(1, restClient.sendTelemetryStatsCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }

    override func tearDown() {}
}
