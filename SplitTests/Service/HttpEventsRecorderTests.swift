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

class HttpEventsRecorderTests: XCTestCase {

    var restClient: RestClientStub!
    var recorder: DefaultHttpEventsRecorder!
    let events = TestingHelper.createEvents()

    override func setUp() {
        restClient = RestClientStub()
        recorder = DefaultHttpEventsRecorder(restClient: restClient)
    }

    func testServerNoReachable() {
        restClient.isServerAvailable = false
        var isError = false
        do {
            let _ = try recorder.execute(events)
        } catch {
            isError = true
        }
        XCTAssertTrue(isError)
    }

    func testSuccessSending() throws {
        restClient.isServerAvailable = true

        try recorder.execute(events)

        XCTAssertEqual(1, restClient.getSendTrackEventsCount())
    }

    override func tearDown() {
    }
}

