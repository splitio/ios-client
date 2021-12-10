//
//  HttpTelemetryConfigRecorderTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Dic-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpTelemetryConfigRecorderTest: XCTestCase {

    var restClient: RestClientStub!
    var recorder: DefaultHttpTelemetryConfigRecorder!
    let telemetryConfig = TestingHelper.createTelemetryConfig()

    override func setUp() {
        restClient = RestClientStub()
        recorder = DefaultHttpTelemetryConfigRecorder(restClient: restClient)
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
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(telemetryConfig)

        XCTAssertEqual(1, restClient.sendTelemetryConfigCount)
    }

    override func tearDown() {
    }
}

