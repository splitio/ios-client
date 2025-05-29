//
//  HttpRecorderTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpImpressionsRecorderTests: XCTestCase {
    var restClient: RestClientStub!
    var recorder: DefaultHttpImpressionsRecorder!
    let impressions = TestingHelper.createTestImpressions()
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        recorder = DefaultHttpImpressionsRecorder(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(impressions)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(impressions)

        XCTAssertEqual(1, restClient.getSendImpressionsCount())
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }

    override func tearDown() {}
}
