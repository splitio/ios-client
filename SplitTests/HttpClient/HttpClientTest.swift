//
//  HttpClientTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 07/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpClientTest: XCTestCase {
    var httpClient: HttpClient!
    var httpSession: HttpSessionMock!
    var requestManager: HttpRequestManagerMock!
    var factory: EndpointFactory!
    var serviceEndpoints: ServiceEndpoints!

    override func setUp() {
        // Create a http client with a mocked session to evaluate behavior
        httpSession = HttpSessionMock()
        requestManager = HttpRequestManagerMock()

        httpClient = DefaultHttpClient(
            session: httpSession,
            requestManager: requestManager)
        serviceEndpoints = ServiceEndpoints.builder().build()
        factory = EndpointFactory(
            serviceEndpoints: serviceEndpoints,
            apiKey: CommonValues.apiKey,
            splitsQueryString: "")
    }

    func testDataRequest() throws {
        // When data request is sent
        // http session has to create a new task
        // and request manager should enqueue it
        // also, get response closure should be called
        // with received data appended by request manager
        var splitsChange: SplitChange? = nil
        let dummyChanges = Data(IntegrationHelper.emptySplitChanges(since: 1, till: 2).utf8)
        let expectation = XCTestExpectation(description: "complete req")
        _ = try httpClient.sendRequest(endpoint: factory.splitChangesEndpoint, parameters: ["since": 100])
            .getResponse(completionHandler: { response in
                splitsChange = try? response.result.value?.decode(TargetingRulesChange.self)?.featureFlags
                expectation.fulfill()
            }, errorHandler: { error in })

        requestManager.append(data: dummyChanges, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)
        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertEqual(1, splitsChange?.since)
        XCTAssertEqual(2, splitsChange?.till)
        XCTAssertFalse(requestManager.request.method.isUpload)
    }

    func testDataRequestWithOrder() throws {
        var splitsChange: SplitChange? = nil
        let dummyChanges = Data(IntegrationHelper.emptySplitChanges(since: 1, till: 2).utf8)
        let expectation = XCTestExpectation(description: "complete req")
        _ = try httpClient.sendRequest(
            endpoint: factory.splitChangesEndpoint,
            parameters: HttpParameters([
                HttpParameter(key: "s", value: "2.2"),
                HttpParameter(key: "since", value: 100),
                HttpParameter(key: "rbSince", value: 120),
            ]))
            .getResponse(completionHandler: { response in
                splitsChange = try? response.result.value?.decode(TargetingRulesChange.self)?.featureFlags
                expectation.fulfill()
            }, errorHandler: { error in })

        requestManager.append(data: dummyChanges, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)
        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertEqual(1, splitsChange?.since)
        XCTAssertEqual(2, splitsChange?.till)
        XCTAssertFalse(requestManager.request.method.isUpload)
        XCTAssertEqual(
            "https://sdk.split.io/api/splitChanges?s=2.2&since=100&rbSince=120",
            requestManager.request.url.absoluteString)
    }

    func testDataRequestError() throws {
        // When an error occurred errorHandler closure should be called
        var theError: HttpError?
        let expectation = XCTestExpectation(description: "complete req err")
        _ = try httpClient.sendRequest(endpoint: factory.splitChangesEndpoint, parameters: ["since": 100])
            .getResponse(
                completionHandler: { response in },
                errorHandler: { error in
                    theError = error
                    expectation.fulfill()
                })

        requestManager.complete(taskIdentifier: 1, error: HttpError.couldNotCreateRequest(message: "Error"))
        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertEqual("Error", theError?.message)
    }

    func testUploadRequest() throws {
        // When upload request is sent
        // http session has to create a new task
        // and request manager should enqueue it
        // also, get response closure should be called
        // for split endpoints received data should not be appended by request manager
        var isSuccess = false

        let dummyImpressions = Data(IntegrationHelper.dummyReducedImpressions().utf8)
        let expectation = XCTestExpectation(description: "complete req")
        do {
            _ = try httpClient.sendRequest(
                endpoint: factory.impressionsEndpoint,
                parameters: nil,
                headers: nil,
                body: dummyImpressions).getResponse(completionHandler: { response in
                isSuccess = response.result.isSuccess
                expectation.fulfill()
            }, errorHandler: { error in })
        } catch {
            print(error.localizedDescription)
            throw GenericError.unknown(message: error.localizedDescription)
        }

        _ = requestManager.set(responseCode: 200, to: 1)
        requestManager.complete(taskIdentifier: 1, error: nil)
        wait(for: [expectation], timeout: 10)

        let impSent = try Json((requestManager.request as? HttpDataRequest)?.body).decode([ImpressionsTest].self)

        XCTAssertTrue(isSuccess)
        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertTrue(requestManager.request.method.isUpload)
        XCTAssertEqual("test1", impSent?[0].testName)
    }

    func testStreamRequest() throws {
        // When data request is sent
        // http session has to create a new task
        // and request manager should enqueue it
        // also, get response and data received closures should be called
        // On close closure test will be added
        /// TODO: Add on close test

        var dataArrived = false
        var responseOk = false
        var closedOk = false
        let dataString = "data arrived"
        let data = Data(dataString.utf8)
        var receivedData: Data? = nil
        let dataExp = XCTestExpectation(description: "data")
        let respExp = XCTestExpectation(description: "resp")
        let closeExp = XCTestExpectation(description: "close")
        _ = try httpClient.sendStreamRequest(
            endpoint: factory.splitChangesEndpoint,
            parameters: ["since": 100],
            headers: nil)
            .getResponse(
                responseHandler: { response in
                    responseOk = true
                    respExp.fulfill()
                }, incomingDataHandler: { data in
                    dataArrived = true
                    receivedData = data
                    dataExp.fulfill()
                },
                closeHandler: {
                    closedOk = true
                    closeExp.fulfill()
                },
                errorHandler: { error in
                })

        requestManager.append(data: data, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)
        requestManager.complete(taskIdentifier: 1, error: nil)
        wait(for: [dataExp, respExp], timeout: 10)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertEqual(dataString, receivedData?.stringRepresentation)
        XCTAssertTrue(dataArrived)
        XCTAssertTrue(responseOk)
        XCTAssertTrue(closedOk)
    }
}
