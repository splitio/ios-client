//
//  HttpUniqueKeyRecorderTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class HttpUniqueKeyRecorderTests: XCTestCase {
    var restClient: RestClientStub!
    var recorder: DefaultHttpUniqueKeysRecorder!
    let uniqueKeys = TestingHelper.createUniqueKeys(keyCount: 5, featureCount: 15)
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        restClient = RestClientStub()
        telemetryProducer = TelemetryStorageStub()
        recorder = DefaultHttpUniqueKeysRecorder(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(uniqueKeys)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
        XCTAssertEqual(0, telemetryProducer.recordHttpLastSyncCallCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpLatencyCallCount)
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(uniqueKeys)

        XCTAssertEqual(1, restClient.sendUniqueKeysCount)
        XCTAssertEqual(0, telemetryProducer.recordHttpErrorCallCount)
    }

    override func tearDown() {}
}
