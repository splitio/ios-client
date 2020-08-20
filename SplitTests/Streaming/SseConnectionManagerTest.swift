//
//  SseConnectionManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SseConnectionManagerTest: XCTestCase {

    var connectionManager: SseConnectionManager!
    var sseAuthenticator: SseAuthenticatorStub!
    var sseClient: SseClientMock!
    var authBackoff: ReconnectBackoffCounterStub!
    var sseBackoff: ReconnectBackoffCounterStub!
    var timersManager: TimersManagerMock!
    let userKey = IntegrationHelper.dummyUserKey

    override func setUp() {
        sseAuthenticator = SseAuthenticatorStub()
        sseClient = SseClientMock()
        authBackoff = ReconnectBackoffCounterStub()
        sseBackoff = ReconnectBackoffCounterStub()
        timersManager = TimersManagerMock()
        connectionManager = DefaultSseConnectionManager(userKey: userKey, sseAuthenticator: sseAuthenticator, sseClient: sseClient, authBackoffCounter: authBackoff,
                                                        sseBackoffCounter: sseBackoff, timersManager: timersManager)

    }

    func testStartFullConnectionOk() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels
        // Returning ok token with streaming enabled
        // Also an expectation is added to be fullfiled when timer is added
        // in order to avoid using sleep to wait for all process finished
        
        let exp = XCTestExpectation(description: "finish")
        timersManager.addExpectationFor(timer: .keepAlive, expectation: exp)

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(userKey, sseAuthenticator.userKey!)
        XCTAssertEqual("thetoken", sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertEqual(0, authBackoff.retryCallCount)
        XCTAssertEqual(0, sseBackoff.retryCallCount)
        XCTAssertTrue(authBackoff.resetCounterCalled)
        XCTAssertTrue(sseBackoff.resetCounterCalled)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
    }

    func testStartAuthReintent() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels
        // Returning ok token with streaming enabled
        // Also an expectation is added to be fullfiled when timer is added
        // in order to avoid using sleep to wait for all process finished

        let exp = XCTestExpectation(description: "finish")
        timersManager.addExpectationFor(timer: .keepAlive, expectation: exp)

        sseAuthenticator.results = [recoverableAuthResult(), recoverableAuthResult(), successAuthResult()]
        sseClient.results = [recoverableConnResult(), recoverableConnResult(), successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 80)

        XCTAssertEqual(userKey, sseAuthenticator.userKey!)
        XCTAssertEqual("thetoken", sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertEqual(2, authBackoff.retryCallCount)
        XCTAssertEqual(2, sseBackoff.retryCallCount)
        XCTAssertTrue(authBackoff.resetCounterCalled)
        XCTAssertTrue(sseBackoff.resetCounterCalled)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
    }

    override func tearDown() {
    }

    private func successAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(success: true, errorIsRecoverable: false,
                                       pushEnabled: true, jwtToken: dummyToken())
    }

    private func recoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(success: false, errorIsRecoverable: true,
                                       pushEnabled: true, jwtToken: nil)
    }

    private func noRecoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(success: false, errorIsRecoverable: false,
                                       pushEnabled: true, jwtToken: nil)
    }

    private func successConnResult() -> SseConnectionResult {
        return SseConnectionResult(success: true, errorIsRecoverable: true)
    }

    private func recoverableConnResult() -> SseConnectionResult {
        return SseConnectionResult(success: false, errorIsRecoverable: true)
    }

    private func noRecoverableConnResult() -> SseConnectionResult {
        return SseConnectionResult(success: false, errorIsRecoverable: false)
    }

    private func dummyToken() -> JwtToken {
        return JwtToken(issuedAt: 1000, expirationTime: 10000, channels: ["ch1", "ch2"], rawToken: "thetoken")
    }

}
