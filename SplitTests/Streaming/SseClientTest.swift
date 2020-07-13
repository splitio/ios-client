//
// SSEClientTest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SseClientTest: XCTestCase {
    var httpClient: HttpClientMock!
    var sseClient: SseClient
    var streamRequest: HttpStreamRequest!

    override func setUp() {

    }

    func testConnect() {
        let exp = XCTestExpectation("connect")
        var connected = false
        sseClient.connect(url: url, httpClient: httpClient)

        sseClient.onConnect() {
            connected = true
            exp.fullfil()
        }
        streamRequest.setResponse(code: 200)
        wait(for: [exp], timeout: 2)

        XCTAssertTrue(connected)
    }

    func testOnMessage() {

    }

    func testOnErrorRecoverable() {

    }

    func testOnErrorNoRecoverable() {

    }

    func testOnKeepAlive() {

    }

    func testDisconnect() {
    }

    override func tearDown() {
    }

}
