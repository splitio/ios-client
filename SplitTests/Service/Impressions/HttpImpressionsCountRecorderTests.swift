//
//  HttpImpressionsCountRecorderTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jul-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpImpressionsCountRecorderTests: XCTestCase {
    var restClient: RestClientStub!
    var recorder: DefaultHttpImpressionsCountRecorder!
    let counts = TestingHelper.createImpressionsCount()
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        recorder = DefaultHttpImpressionsCountRecorder(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(ImpressionsCount(perFeature: counts))
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(ImpressionsCount(perFeature: counts))

        XCTAssertEqual(1, restClient.getSendImpressionsCountCount())
        XCTAssertEqual(1, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(1, telemetryProducer.recordHttpLatencyCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }

    override func tearDown() {}
}
