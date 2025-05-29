//
//  HttpTelemetryConfigRecorderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Dic-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpTelemetryConfigRecorderTest: XCTestCase {
    var restClient: RestClientStub!
    var recorder: DefaultHttpTelemetryConfigRecorder!
    let telemetryConfig = TestingHelper.createTelemetryConfig()
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        recorder = DefaultHttpTelemetryConfigRecorder(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(telemetryConfig)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(telemetryConfig)

        XCTAssertEqual(1, restClient.sendTelemetryConfigCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }

    override func tearDown() {}
}
