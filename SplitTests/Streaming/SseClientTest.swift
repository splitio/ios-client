//
// SSEClientTest.swift
// Split
//
// Created by Javier L. Avrudsky on 12/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SseClientTest: XCTestCase {
    var httpClient: HttpClientMock!
    var sseClient: DefaultSseClient!
    var streamRequest: HttpStreamRequestMock!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    let sseAuthToken = "SSE_AUTH_TOKEN"
    let sseChannels = ["channel1", "channel2"]
    var sseHandler: SseHandlerStub!

    override func setUp() {
        sseHandler = SseHandlerStub()
        let session = HttpSessionMock()
        httpClient = HttpClientMock(session: session)
        let sseEndpoint = EndpointFactory(
            serviceEndpoints: ServiceEndpoints.builder().build(),
            apiKey: apiKey,
            splitsQueryString: "").streamingEndpoint
        sseClient = DefaultSseClient(endpoint: sseEndpoint, httpClient: httpClient, sseHandler: sseHandler)
    }

    func testConnect() {
        // SSE client returns true connections was successful.
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        let conExp = XCTestExpectation(description: "conn")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp
        var connected = false

        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            connected = success
            conExp.fulfill()
        }

        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)

        wait(for: [reqExp], timeout: 5)

        request.notifyIncomingData(Data(":keepalive\n".utf8))

        wait(for: [conExp], timeout: 5)

        XCTAssertTrue(connected)
    }

    func testOnMessage() {
        // SSE client has to fire onMessageHandler if available when an incoming message
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // Then we simulate incoming data and wait for onMessageHandler execution
        let reqExp = XCTestExpectation(description: "req")
        let conExp = XCTestExpectation(description: "connect")
        let msgExp = XCTestExpectation(description: "message")

        // Set the amount of simulated incoming messages
        httpClient.streamReqExp = reqExp

        sseHandler.messageExpectation = msgExp
        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            conExp.fulfill()
        }

        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [reqExp], timeout: 5)

        request.notifyIncomingData(Data(":keepalive".utf8))
        request.notifyIncomingData(Data("message".utf8))

        wait(for: [conExp, msgExp], timeout: 5)

        XCTAssertTrue(sseHandler.handleIncomingCalled)
    }

    func testOnErrorRecoverable() {
        // Test recoverable error (Internal server error)
        onErrorTest(code: 500, shouldBeRecoverable: true)
    }

    func testOnErrorNonRecoverable() {
        // Test no recoverable error (client error)
        onErrorTest(code: 401, shouldBeRecoverable: false)
    }

    func onErrorTest(code: Int, shouldBeRecoverable: Bool) {
        // SSE client returns success = false if connection was not successful.
        // Also the flag isRecoverable indicates if we retry to connect
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will be called with an error http code so OnErrorHandler has to be executed
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp
        var connected = false
        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            connected = success
        }

        sleep(1)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: code)
        wait(for: [reqExp], timeout: 5)

        XCTAssertFalse(connected)
        XCTAssertEqual(sseHandler.errorRetryableReported, shouldBeRecoverable)
    }

    func testOnErrorExceptionWhileRequest() {
        // SSE client returns success = false if connection was not successful.
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will throw an exception to check if handled correctly
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp
        httpClient.throwOnSend = true

        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
        }

        wait(for: [reqExp], timeout: 5)

        XCTAssertFalse(sseHandler.errorRetryableReported)
    }

    func testOnErrorAfterConnectionSuccess() {
        // SSE client has to fire onErrorHandler if available when an error occurs
        // after connection was successful
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will be called with an error http code so OnErrorHandler has to be executed
        let conExp = XCTestExpectation(description: "conn")
        let errExp = XCTestExpectation(description: "error")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp
        sseHandler.errorExpectation = errExp

        var connected = false
        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            connected = success
            conExp.fulfill()
        }

        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [reqExp], timeout: 5)

        request.notifyIncomingData(Data(":keepalive".utf8))
        wait(for: [conExp], timeout: 5)
        request.complete(error: HttpError.unknown(code: -1, message: "unknown error"))
        wait(for: [errExp], timeout: 5)

        XCTAssertTrue(connected)
        XCTAssertTrue(sseHandler.errorReportedCalled)
        XCTAssertTrue(sseHandler.errorRetryableReported)
    }

    func testDisconnectFromServer() {
        // SSE client has to fire onOpenHandler if available when connection is opened
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect. Then we wait for onOpenHandler execution
        let conExp = XCTestExpectation(description: "connect")
        let discExp = XCTestExpectation(description: "disconnect")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp

        sseHandler.errorExpectation = discExp

        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            conExp.fulfill()
        }

        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [reqExp], timeout: 5)

        request.notifyIncomingData(Data(":keepalive".utf8))
        wait(for: [conExp], timeout: 5)
        request.complete(error: nil)
        wait(for: [discExp], timeout: 5)

        XCTAssertTrue(sseHandler.errorReportedCalled)
        XCTAssertTrue(sseHandler.errorRetryableReported)
    }

    func testDisconnect() {
        // SSE client has to fire onOpenHandler if available when connection is opened
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect. Then we wait for onOpenHandler execution
        let conExp = XCTestExpectation(description: "connect")
        let discExp = XCTestExpectation(description: "disconnect")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp

        let requestMock = HttpStreamRequestMock()
        requestMock.closeExpectation = discExp
        httpClient.httpStreamRequest = requestMock

        sseClient.connect(token: sseAuthToken, channels: sseChannels) { success in
            conExp.fulfill()
        }

        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [reqExp], timeout: 5)

        request.notifyIncomingData(Data(":keepalive".utf8))
        wait(for: [conExp], timeout: 5)

        sseClient.disconnect()
        wait(for: [discExp], timeout: 5)

        XCTAssertTrue(requestMock.closeCalled)
    }

    override func tearDown() {}
}
