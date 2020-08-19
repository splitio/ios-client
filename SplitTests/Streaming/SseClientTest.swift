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
    var sseClient: DefaultSseClient!
    var streamRequest: HttpStreamRequest!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    let sseAuthToken = "SSE_AUTH_TOKEN"
    let sseChannels = ["channel1", "channel2"]

    override func setUp() {
        let session = HttpSessionMock()
        httpClient = HttpClientMock(session: session)
        let sseEndpoint = EndpointFactory(serviceEndpoints: ServiceEndpoints.builder().build(),
                                          apiKey: apiKey, userKey: userKey).streamingEndpoint
        sseClient = DefaultSseClient(endpoint: sseEndpoint, httpClient: httpClient)
    }

    func testConnect() {
        // SSE client has to fire onOpenHandler if available when connection is opened
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect. Then we wait for onOpenHandler execution
        let conExp = XCTestExpectation(description: "conn")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp

        var result: SseConnectionResult?
        DispatchQueue.global().async {
            result = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
            conExp.fulfill()
        }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)

        wait(for: [conExp], timeout: 5)

        XCTAssertTrue(result?.success ?? false)
    }

    /// TODO: Update this test when StreamingParser implemented
    func testOnMessage() {
        // SSE client has to fire onMessageHandler if available when an incoming message
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // Then we simulate incoming data and wait for onMessageHandler execution
        let reqExp = XCTestExpectation(description: "req")
        let conExp = XCTestExpectation(description: "connect")
        let msgExp = XCTestExpectation(description: "message")
        let msgCount = 3
        var msgCounter = 0
        var messages: [String] = [String]()
        // Set the amount of simulated incoming messages
        httpClient.streamReqExp = reqExp

        sseClient.onMessageHandler = { message in
            msgCounter+=1
            messages.append(message.stringRepresentation)
            if msgCounter == msgCount {
                msgExp.fulfill()
            }
        }

        DispatchQueue.global().async {
              _ = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
              conExp.fulfill()
          }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [conExp], timeout: 5)

        for i in 1..<4 {
            let data = Data("msg\(i)".utf8)
            request.notifyIncomingData(data)
        }
        wait(for: [msgExp], timeout: 5)

        XCTAssertEqual(msgCount, messages.count)
        XCTAssertEqual("msg1", messages[0])
        XCTAssertEqual("msg2", messages[1])
        XCTAssertEqual("msg3", messages[2])
    }

    func testOnErrorRecoverable() {
        // Test recoverable error (Internal server error)
        onErrorTest(code: 500, shouldBeRecoverable: true)
    }

    func testOnErrorNonRecoverable() {
        // Test recoverable error (unauthorized)
        onErrorTest(code: 401, shouldBeRecoverable: false)
    }

    func onErrorTest(code: Int, shouldBeRecoverable: Bool) {
        // SSE client has to fire onErrorHandler if available when an error occurs
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will be called with an error http code so OnErrorHandler has to be executed
        let conExp = XCTestExpectation(description: "conn")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp

        var result: SseConnectionResult?
        DispatchQueue.global().async {
            result = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
            conExp.fulfill()
        }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: code)
        wait(for: [conExp], timeout: 5)

        XCTAssertFalse(result?.success ?? true)
        XCTAssertEqual(shouldBeRecoverable, result?.errorIsRecoverable ?? !shouldBeRecoverable)
    }

    func testOnErrorExceptionWhileRequest() {
        // SSE client has to fire onErrorHandler if available when an error occurs
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will throw an exception to check if handled correctly
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp
        httpClient.throwOnSend = true


        var result: SseConnectionResult?
        DispatchQueue.global().async {
            result = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
        }

        wait(for: [reqExp], timeout: 5)

        XCTAssertFalse(result?.success ?? true)
        XCTAssertEqual(false, result?.errorIsRecoverable ?? true)
    }

    func testOnErrorAfterConnectionSuccess() {
        // SSE client has to fire onErrorHandler if available when an error occurs
        // Here reqExp expectation is fired with delay on HttpClient mock
        // to make sure that request.setResponse which is executed when headers received
        // run after on connect.
        // On response will be called with an error http code so OnErrorHandler has to be executed
        let conExp = XCTestExpectation(description: "conn")
        let errExp = XCTestExpectation(description: "error")
        let reqExp = XCTestExpectation(description: "req")
        httpClient.streamReqExp = reqExp

        var onErrorCalled = false
        var isErrorRecoverable = true
        sseClient.onErrorHandler = { isRecoverable in
            onErrorCalled = true
            isErrorRecoverable = isRecoverable
            errExp.fulfill()
        }

        var result: SseConnectionResult?
        DispatchQueue.global().async {
            result = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
            conExp.fulfill()
        }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [conExp], timeout: 5)
        request.complete(error: HttpError.unknown(message: "unknown error"))
        wait(for: [errExp], timeout: 5)

        XCTAssertTrue(result?.success ?? false)
        XCTAssertTrue(onErrorCalled)
        XCTAssertFalse(isErrorRecoverable)
    }


    func testOnKeepAlive() {
        // TODO: Implement this test when stream parser complete
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

        var disconnected = false

        sseClient.onDisconnectHandler = {
            disconnected = true
            discExp.fulfill()
        }

        DispatchQueue.global().async {
            _ = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
            conExp.fulfill()
        }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [conExp], timeout: 5)
        request.complete(error: nil)
        wait(for: [discExp], timeout: 5)

        XCTAssertTrue(disconnected)
    }

    override func tearDown() {
    }


    /// The following code is used while developing streaming feature/
    /// TODO: Remove when implementation is finished
//    func testRConnect() {
//        let channels = [""]
//        let token = ""
//        let serviceEndpoints =  ServiceEndpoints.builder().build()
//        let sseEndpoint = EndpointFactory(serviceEndpoints: serviceEndpoints,
//        apiKey: "", userKey: "javi").streamingEndpoint
//        var httpSessionConfig = HttpSessionConfig()
//        httpSessionConfig.readTimeout = 80
//
//        let realHttpClient = DefaultHttpClient(configuration: httpSessionConfig)
//        let localSseClient = SseClient(endpoint: sseEndpoint, httpClient: DefaultHttpClient.shared)
//        localSseClient.onOpenHandler = {
//            print("conn oppened!!!!!")
//        }
//
//        localSseClient.onErrorHandler = { isRec in
//            print("conn error!!!!! \(isRec)")
//        }
//
//        localSseClient.onMessageHandler =  { message in
//            print("msg received: \(message.stringRepresentation)")
//        }
//
//        localSseClient.onDisconnectHandler = {
//            print("diconnected")
//        }
//        localSseClient.connect(token: token, channels: channels)
//        sleep(90000)
//    }

}
