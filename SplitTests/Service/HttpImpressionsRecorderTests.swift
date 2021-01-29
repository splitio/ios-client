//
//  HttpRecorderTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpImpressionsRecorderTests: XCTestCase {

    var restClient: RestClientStub!
    var recorder: DefaultHttpImpressionsRecorder!
    let impressions = TestingHelper.createTestImpressions()

    override func setUp() {
        restClient = RestClientStub()
        recorder = DefaultHttpImpressionsRecorder(restClient: restClient)
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
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(impressions)

        XCTAssertEqual(1, restClient.getSendImpressionsCount())
    }

    override func tearDown() {
    }
}

