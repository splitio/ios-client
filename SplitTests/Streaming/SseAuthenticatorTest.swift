//
//  SseAuthenticatorTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 07/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split



class SseAuthenticatorTest: XCTestCase {
    
    let restClient = RestClientStub()
    let kUserKey = IntegrationHelper.dummyUserKey

    let rawToken = "this_token_raw"
    
    override func setUp() {
    }
    
    func testSuccesfulRequest() {
        // Check successful response

        let response = SseAuthenticationResponse(pushEnabled: true, token:rawToken)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient)

        let result = sseAuthenticator.authenticate(userKey: kUserKey)

        XCTAssertEqual(true, result.pushEnabled)
        XCTAssertEqual(true, result.success)
        XCTAssertEqual(rawToken, result.rawToken)
    }

    func testEmptyTokenResponse() {
        // Check empty token error response
        let response = SseAuthenticationResponse(pushEnabled: true, token: "")
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient)

        let result = sseAuthenticator.authenticate(userKey: kUserKey)

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertEqual(nil, result.rawToken)
    }

    func testNullTokenResponse() {
        // Check null token error response
        let response = SseAuthenticationResponse(pushEnabled: true, token: nil)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient)

        let result = sseAuthenticator.authenticate(userKey: kUserKey)

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertEqual(nil, result.rawToken)
    }

    func testRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        restClient.updateFailedSseAuth(error: HttpError.unknown(message: "unknown"))
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient)

        let result = sseAuthenticator.authenticate(userKey: kUserKey)

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(true, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertNil(result.rawToken)
    }

    func testNoRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        restClient.updateFailedSseAuth(error: HttpError.clientRelated)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient)


        let result = sseAuthenticator.authenticate(userKey: kUserKey)

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertNil(result.rawToken)
    }
    
    override func tearDown() {
        
    }
}
