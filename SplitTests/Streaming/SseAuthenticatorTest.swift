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
    
    override func setUp() {
    }
    
    func testSuccesfulRequest() {
        // Check successful response
        // Using parser mock to avoid sending real token string to create sse response
        let token = JwtToken(issuedAt: 100, expirationTime: 200,
                             channels: ["channel1", "channel2"], rawToken: "therawtoken")
        let parser = JwtParserStub(token: token)
        let response = SseAuthenticationResponse(pushEnabled: true, token: "")
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient, jwtParser: parser)
        
        
        let result = sseAuthenticator.authenticate(userKey: kUserKey)
        let expToken = result.jwtToken

        XCTAssertEqual(true, result.pushEnabled)
        XCTAssertEqual(true, result.success)
        XCTAssertEqual(expToken?.issuedAt, token.issuedAt)
        XCTAssertEqual(expToken?.expirationTime, token.expirationTime)
        XCTAssertEqual(expToken?.channels.count, token.channels.count)
        XCTAssertEqual(expToken?.rawToken, token.rawToken)
    }

    func testTokenParserError() {
        // Check token error response
        // Using parser mock to avoid sending real token string to create sse response
        let parser = JwtParserStub(error: JwtTokenError.tokenIsInvalid)
        let response = SseAuthenticationResponse(pushEnabled: true, token: "")
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient, jwtParser: parser)


        let result = sseAuthenticator.authenticate(userKey: kUserKey)
        let expToken = result.jwtToken

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.pushEnabled)

        XCTAssertNil(expToken)
    }

    func testRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        let token = JwtToken(issuedAt: 100, expirationTime: 200,
                             channels: [], rawToken: "")
        let parser = JwtParserStub(token: token)
        restClient.updateFailedSseAuth(error: HttpError.unknown(message: "unknown"))
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient, jwtParser: parser)


        let result = sseAuthenticator.authenticate(userKey: kUserKey)
        let expToken = result.jwtToken

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(true, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)

        XCTAssertNil(expToken)
    }

    func testNoRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        let token = JwtToken(issuedAt: 100, expirationTime: 200,
                             channels: [], rawToken: "")
        let parser = JwtParserStub(token: token)
        restClient.updateFailedSseAuth(error: HttpError.authenticationFailed)
        let sseAuthenticator = DefaultSseAuthenticator(restClient: restClient, jwtParser: parser)


        let result = sseAuthenticator.authenticate(userKey: kUserKey)
        let expToken = result.jwtToken

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)

        XCTAssertNil(expToken)
    }
    
    override func tearDown() {
        
    }
}
