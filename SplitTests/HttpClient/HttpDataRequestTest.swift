//
//  HttpDataRequestTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 26/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class HttpDataRequestTest: XCTestCase {

    var httpSession = HttpSessionMock()
    let url = URL(string: "http://split.com")!
    override func setUp() {
    }

    func testRequestCreation() throws {
        // Testing parameter setup on request creation
        let parameters: HttpParameters = ["p1": "v1", "p2": 2]
        let headers: HttpHeaders = ["h1": "v1", "h2": "v2"]
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: url, method: .get, parameters: parameters, headers: headers)

        XCTAssertEqual("v1", httpRequest.parameters!["p1"] as! String)
        XCTAssertEqual(2, httpRequest.parameters!["p2"] as! Int)
        XCTAssertEqual("v1", httpRequest.headers["h1"])
        XCTAssertEqual("v2", httpRequest.headers["h2"])
        XCTAssertEqual(headers, httpRequest.headers)
        XCTAssertTrue("http://split.com?p2=2&p1=v1" == httpRequest.url.absoluteString || "http://split.com?p1=v1&p2=2" == httpRequest.url.absoluteString)
    }

    func testRequestCreationWithOrder() throws {
        // Testing parameter setup on request creation
        let parameters: HttpParameters = HttpParameters([HttpParameter(key: "p2", value: 2), HttpParameter(key: "p3", value: [1,2,3]), HttpParameter(key: "defaultParam"), HttpParameter(key: "p1", value: "v1")])
        let headers: HttpHeaders = ["h1": "v1", "h2": "v2"]
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: URL(string: (url.absoluteString + "?defaultParam=4"))!, method: .get, parameters: parameters, headers: headers)

        XCTAssertEqual("v1", httpRequest.parameters!["p1"] as! String)
        XCTAssertEqual(2, httpRequest.parameters!["p2"] as! Int)
        XCTAssertEqual([1,2,3], httpRequest.parameters!["p3"] as! [Int])
        XCTAssertEqual("v1", httpRequest.headers["h1"])
        XCTAssertEqual("v2", httpRequest.headers["h2"])
        XCTAssertEqual(headers, httpRequest.headers)
        XCTAssertEqual("http://split.com?p2=2&p3=1,2,3&defaultParam=4&p1=v1", httpRequest.url.absoluteString)
    }

    func testRequestEnquedOnSend() throws {
        // When a request is sent, it has to be created in
        // in an http session
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: url, method: .get, parameters: nil, headers: nil)

        httpRequest.send()

        XCTAssertEqual(1, httpSession.dataTaskCallCount)

    }

    func testOnResponseCompletedOk() throws {
        // On response completed request should fire completion handler
        // so, we test that closure are called on that scenario having
        // the corresponding received data
        var responseIsSuccess = false
        let textData = "{\"d\":[], \"s\":1, \"t\":2}"
        var receivedData: SplitChange? = nil
        let onCloseExpectation = XCTestExpectation(description: "complete request")
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: url, method: .get, parameters: nil, headers: nil)

        _ = httpRequest.getResponse(completionHandler: { response in
            responseIsSuccess = response.result.isSuccess
            do {
                receivedData = try response.result.value?.decode(SplitChange.self)
            } catch {
                print(error)
            }
            onCloseExpectation.fulfill()

        }, errorHandler: { error in
        })

        httpRequest.send()

        httpRequest.notifyIncomingData(Data(textData.utf8))
        httpRequest.setResponse(code: 200)
        httpRequest.complete(error: nil)

        wait(for: [onCloseExpectation], timeout: 5)

        XCTAssertTrue(responseIsSuccess)
        XCTAssertEqual(0, receivedData?.splits.count)
        XCTAssertEqual(1, receivedData?.since)
        XCTAssertEqual(2, receivedData?.till)
    }

    func testOnResponseCompletedError() throws {
        // On response completed request should fire completion handler
        // we test that closure called on that scenario
        // simulating a failed response

        var responseIsSuccess = true
        var receivedData: Json? = nil
        let onCloseExpectation = XCTestExpectation(description: "complete request")
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: url, method: .get, parameters: nil, headers: nil)

        _ = httpRequest.getResponse(completionHandler: { response in
            responseIsSuccess = response.result.isSuccess
            receivedData = response.result.value
            onCloseExpectation.fulfill()
        }, errorHandler: { error in
        })

        httpRequest.send()

        httpRequest.setResponse(code: 500)
        httpRequest.complete(error: nil)

        wait(for: [onCloseExpectation], timeout: 5)

        XCTAssertFalse(responseIsSuccess)
        XCTAssertNil(receivedData)
    }

    func testError() throws {
        // On error while running request should fire
        // error handler closure.

        var responseIsSuccess = false
        var errorHasOcurred = false
        var theError: HttpError?
        let onCloseExpectation = XCTestExpectation(description: "complete request")
        let httpRequest = try DefaultHttpDataRequest(session: httpSession, url: url, method: .get, parameters: nil, headers: nil)

        _ = httpRequest.getResponse(completionHandler: { response in
            responseIsSuccess = true
        }, errorHandler: { error in
            errorHasOcurred = true
            theError = error as HttpError
            onCloseExpectation.fulfill()
        })

        httpRequest.send()
        httpRequest.complete(error: HttpError.couldNotCreateRequest(message: "Req error"))

        wait(for: [onCloseExpectation], timeout: 5)

        XCTAssertFalse(responseIsSuccess)
        XCTAssertTrue(errorHasOcurred)
        XCTAssertEqual("Req error", theError?.message)
    }

    override func tearDown() {
    }
}
