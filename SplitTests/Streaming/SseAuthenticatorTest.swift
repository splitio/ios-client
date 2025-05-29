//
//  SseAuthenticatorTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 07/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SseAuthenticatorTest: XCTestCase {
    let restClient = RestClientStub()
    let kUserKey = IntegrationHelper.dummyUserKey

    let rawToken = "this_token_raw"

    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        telemetryProducer = TelemetryStorageStub()
    }

    func testSuccesfulRequest() {
        // Check successful response

        let response = SseAuthenticationResponse(pushEnabled: true, token: rawToken, sseConnectionDelay: 0)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey])

        XCTAssertEqual(true, result.pushEnabled)
        XCTAssertEqual(true, result.success)
        XCTAssertEqual(rawToken, result.rawToken)
    }

    func testSuccesfulMultiUserKeyRequest() {
        // Check successful response

        let response = SseAuthenticationResponse(pushEnabled: true, token: rawToken, sseConnectionDelay: 0)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey, "otherKey"])

        XCTAssertEqual(true, result.pushEnabled)
        XCTAssertEqual(true, result.success)
        XCTAssertEqual(rawToken, result.rawToken)
    }

    func testEmptyTokenResponse() {
        // Check empty token error response
        let response = SseAuthenticationResponse(pushEnabled: true, token: "", sseConnectionDelay: 0)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey])

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertEqual(nil, result.rawToken)
    }

    func testNullTokenResponse() {
        // Check null token error response
        let response = SseAuthenticationResponse(pushEnabled: true, token: nil, sseConnectionDelay: 0)
        restClient.update(response: response)
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey])

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertEqual(nil, result.rawToken)
    }

    func testRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        restClient.updateFailedSseAuth(error: HttpError.unknown(code: -1, message: "unknown"))
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey])

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(true, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertNil(result.rawToken)
    }

    func testNoRecoverableError() {
        // Check token error response
        // If no credentials error, error is recoverable
        restClient.updateFailedSseAuth(error: HttpError.clientRelated(code: -1, internalCode: -1))
        let sseAuthenticator = DefaultSseAuthenticator(
            restClient: restClient,
            syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let result = sseAuthenticator.authenticate(userKeys: [kUserKey])

        XCTAssertEqual(false, result.success)
        XCTAssertEqual(false, result.errorIsRecoverable)
        XCTAssertEqual(false, result.pushEnabled)
        XCTAssertNil(result.rawToken)
    }

    override func tearDown() {}
}
