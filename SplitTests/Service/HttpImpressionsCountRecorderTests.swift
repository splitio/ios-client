//
//  HttpImpressionsCountRecorderTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jul-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class HttpImpressionsCountRecorderTests: XCTestCase {

    var restClient: RestClientStub!
    var recorder: DefaultHttpImpressionsCountRecorder!
    let counts = TestingHelper.createImpressionsCount()

    override func setUp() {
        restClient = RestClientStub()
        recorder = DefaultHttpImpressionsCountRecorder(restClient: restClient)
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
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(ImpressionsCount(perFeature: counts))

        XCTAssertEqual(1, restClient.getSendImpressionsCountCount())
    }

    override func tearDown() {
    }
}

