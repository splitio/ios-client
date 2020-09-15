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
        let sseEndpoint = EndpointFactory(serviceEndpoints: ServiceEndpoints.builder().build(),
                                          apiKey: apiKey, userKey: userKey).streamingEndpoint
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

        DispatchQueue.global().async {
              _ = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
              conExp.fulfill()
          }

        wait(for: [reqExp], timeout: 5)
        let request = httpClient.httpStreamRequest!
        request.setResponse(code: 200)
        wait(for: [conExp], timeout: 5)

        request.notifyIncomingData(Data("message".utf8))

        wait(for: [msgExp], timeout: 5)

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
        // SSE client returns success = false if connection was not successful.
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

        DispatchQueue.global().async {
            _ = self.sseClient.connect(token: self.sseAuthToken, channels: self.sseChannels)
            conExp.fulfill()
        }

        wait(for: [reqExp], timeout: 5)

        requestMock.setResponse(code: 200)
        wait(for: [conExp], timeout: 5)
        sseClient.disconnect()
        wait(for: [discExp], timeout: 5)

        XCTAssertTrue(requestMock.closeCalled)
    }

    override func tearDown() {
    }


    /// The following code is used while developing streaming feature/
    /// TODO: Remove when implementation is finished
//    func testRConnect() {
//        let channels = ["MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits", "MzM5Njc0ODcyNg==_MTExMzgwNjgx_MTcwNTI2MTM0Mg==_mySegments", "control_pri", "control_sec"]
//        let token = "eyJhbGciOiJIUzI1NiIsImtpZCI6IjVZOU05US45QnJtR0EiLCJ0eXAiOiJKV1QifQ.eyJ4LWFibHktY2FwYWJpbGl0eSI6IntcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X01UY3dOVEkyTVRNME1nPT1fbXlTZWdtZW50c1wiOltcInN1YnNjcmliZVwiXSxcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X3NwbGl0c1wiOltcInN1YnNjcmliZVwiXSxcImNvbnRyb2xfcHJpXCI6W1wic3Vic2NyaWJlXCIsXCJjaGFubmVsLW1ldGFkYXRhOnB1Ymxpc2hlcnNcIl0sXCJjb250cm9sX3NlY1wiOltcInN1YnNjcmliZVwiLFwiY2hhbm5lbC1tZXRhZGF0YTpwdWJsaXNoZXJzXCJdfSIsIngtYWJseS1jbGllbnRJZCI6ImNsaWVudElkIiwiZXhwIjoxNTk5NDk3MTEwLCJpYXQiOjE1OTk0OTM1MTB9.OgaNs1OdDrIXyYews_oJBrSv3VyZG2ArkZuutzh1MtI"
//        let serviceEndpoints =  ServiceEndpoints.builder().build()
//        let sseEndpoint = EndpointFactory(serviceEndpoints: serviceEndpoints,
//        apiKey: "", userKey: "javi").streamingEndpoint
//        var httpSessionConfig = HttpSessionConfig()
//        httpSessionConfig.connectionTimeOut = 80
//
//        let realHttpClient = DefaultHttpClient(configuration: httpSessionConfig)
//        let localSseClient = DefaultSseClient(endpoint: sseEndpoint,
//                                              httpClient: realHttpClient, sseHandler: SseHandlerStub())
//
//        localSseClient.connect(token: token, channels: channels)
//        print("connected at: \(Date().description)")
//        sleep(90000)
//    }

}
