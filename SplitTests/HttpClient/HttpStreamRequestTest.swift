//
//  HttpStreamRequestTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpStreamRequestTest: XCTestCase {
    var httpSession = HttpSessionMock()
    let url = URL(string: "http://split.com")!
    override func setUp() {}

    func testRequestCreation() throws {
        let parameters: HttpParameters = ["p1": "v1", "p2": 2]
        let headers: HttpHeaders = ["h1": "v1", "h2": "v2"]
        let httpRequest = try DefaultHttpStreamRequest(
            session: httpSession,
            url: url,
            parameters: parameters,
            headers: headers)

        XCTAssertEqual("v1", httpRequest.parameters!["p1"] as! String)
        XCTAssertEqual(2, httpRequest.parameters!["p2"] as! Int)
        XCTAssertEqual("v1", httpRequest.headers["h1"])
        XCTAssertEqual("v2", httpRequest.headers["h2"])
        XCTAssertEqual(headers, httpRequest.headers)
    }

    func testRequestEnquedOnSend() throws {
        // When a request is sent, it has to be created in
        // in an http session
        let httpRequest = try DefaultHttpStreamRequest(session: httpSession, url: url, parameters: nil, headers: nil)

        httpRequest.send()

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
    }

    func testOnResponseOk() throws {
        // On response ok request should fire responseHandler closure
        // and incomingDataHandler when new data arrives
        // so, we test that closures are called on that scenario

        var responseIsSuccess = false
        var receivedData = ""
        var closedOk = false
        let onCloseExpectation = XCTestExpectation(description: "close request")
        let httpRequest = try DefaultHttpStreamRequest(session: httpSession, url: url, parameters: nil, headers: nil)

        _ = httpRequest.getResponse(responseHandler: { response in
            responseIsSuccess = response.result.isSuccess

        }, incomingDataHandler: { data in
            receivedData.append(data.stringRepresentation)

        }, closeHandler: {
            closedOk = true
            onCloseExpectation.fulfill()
        }, errorHandler: { error in
        })

        httpRequest.send()
        httpRequest.setResponse(code: 200)
        httpRequest.complete(error: nil)
        for i in 0 ..< 5 {
            httpRequest.notifyIncomingData(Data("a\(i)".utf8))
        }

        wait(for: [onCloseExpectation], timeout: 5)

        XCTAssertTrue(responseIsSuccess)
        XCTAssertEqual("a0a1a2a3a4", receivedData)
        XCTAssertTrue(closedOk)
    }

    func testErrorResponse() throws {
        // On error request should fire only responseHandler closure
        // and onDataReceived when new data arrives
        // so, we test that closures are called on that scenario

        var responseIsSuccess = true
        var receivedData = ""
        let onResponseExpectation = XCTestExpectation(description: "close request")
        let httpRequest = try DefaultHttpStreamRequest(session: httpSession, url: url, parameters: nil, headers: nil)

        _ = httpRequest.getResponse(responseHandler: { response in
            responseIsSuccess = response.result.isSuccess
            onResponseExpectation.fulfill()

        }, incomingDataHandler: { data in
            receivedData.append(data.stringRepresentation)

        }, closeHandler: {}, errorHandler: { error in
        })

        httpRequest.send()
        httpRequest.setResponse(code: 400)
        httpRequest.complete(error: nil)

        wait(for: [onResponseExpectation], timeout: 5)

        XCTAssertFalse(responseIsSuccess)
        XCTAssertEqual("", receivedData)
    }

    override func tearDown() {}
}
