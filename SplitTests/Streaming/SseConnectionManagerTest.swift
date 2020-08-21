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
        var expSseAvailable = false
        connectionManager.availabilityHandler = { isEnabled in
            expSseAvailable = isEnabled
            exp.fulfill()
        }

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(userKey, sseAuthenticator.userKey!)
        XCTAssertEqual("thetoken", sseClient.token)
        XCTAssertTrue(expSseAvailable)
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
        var expSseAvailable = false
        connectionManager.availabilityHandler = { isEnabled in
            expSseAvailable = isEnabled
            // streaming available means test is finished
            // so we fullfil expectation here to start assert
            if isEnabled {
                exp.fulfill()
            }
        }

        sseAuthenticator.results = [recoverableAuthResult(), recoverableAuthResult(), successAuthResult()]
        sseClient.results = [recoverableConnResult(), recoverableConnResult(), successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(userKey, sseAuthenticator.userKey!)
        XCTAssertEqual("thetoken", sseClient.token)
        XCTAssertTrue(expSseAvailable)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertEqual(2, authBackoff.retryCallCount)
        XCTAssertEqual(2, sseBackoff.retryCallCount)
        XCTAssertTrue(authBackoff.resetCounterCalled)
        XCTAssertTrue(sseBackoff.resetCounterCalled)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
    }

    func testStreamingDisabled() {
        // When auth endpoint responds with streaming disabled
        // Streaming will be turned off,
        // so this component should notify that streaming is not available,
        // cancel all timers and shutdown sse client
        let exp = XCTestExpectation(description: "finish")
        sseAuthenticator.results = [successAuthResult(pushEnabled: false)]

        var expSseAvailable = true
        connectionManager.availabilityHandler = { isEnabled in
            expSseAvailable = isEnabled
            exp.fulfill()
        }

        connectionManager.start()

        wait(for: [exp], timeout: 3)
        //Thread.sleep(forTimeInterval: 1)

        XCTAssertEqual(userKey, sseAuthenticator.userKey!)
        XCTAssertNil(sseClient.token)
        XCTAssertFalse(sseClient.disconnectCalled)
        XCTAssertFalse(expSseAvailable)
        XCTAssertEqual(0, authBackoff.retryCallCount)
        XCTAssertEqual(0, sseBackoff.retryCallCount)
        XCTAssertFalse(authBackoff.resetCounterCalled)
        XCTAssertFalse(sseBackoff.resetCounterCalled)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .keepAlive))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
    }

    func testStop() {
        // On stop the component should closse sse connection
        // stops keep alive and refresh token timers
        // and notify streaming not available

        let conExp = XCTestExpectation(description: "conn")
        let stopExp = XCTestExpectation(description: "stop")
        var expSseAvailable = false
        connectionManager.availabilityHandler = { isEnabled in
            expSseAvailable = isEnabled
            if isEnabled {
                conExp.fulfill()
            } else {
                stopExp.fulfill()
            }
        }

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [conExp], timeout: 3)

        connectionManager.stop()

        wait(for: [stopExp], timeout: 3)

        XCTAssertFalse(expSseAvailable)
        XCTAssertTrue(sseClient.disconnectCalled)
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .refreshAuthToken))
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .keepAlive))
    }

    func testKeepAliveReceived() {
        // When keep alive is received, keep alive timer should
        // be rescheduled
        let exp = XCTestExpectation(description: "finish")
        connectionManager.availabilityHandler = { isEnabled in
            exp.fulfill()
        }

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 3)

        timersManager.reset()

        sseClient.fireOnKeepAlive()

        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
    }

    func testOnErrorRecoverableReceived() {
        onErrorReceived(isRecoverable: true)
    }

    func testOnErrorNoRecoverableReceived() {
        onErrorReceived(isRecoverable: false)
    }

    private func onErrorReceived(isRecoverable: Bool) {
        // When recoverable error is received, timers has to be
        // cancelled, streaming disabled reported and reconnection started
        // If error is non recoverable, reconnection should not be called
        let conExp = XCTestExpectation(description: "conn")
        let errorExp = XCTestExpectation(description: "finish")
        var expSseAvailable = true
        connectionManager.availabilityHandler = { isEnabled in
            if isEnabled {
                conExp.fulfill()
            } else {
                expSseAvailable = isEnabled
                errorExp.fulfill()
            }
        }

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [conExp], timeout: 3)

        timersManager.reset()
        sseClient.connectCalled = false
        sseClient.fireOnError(isRecoverable: isRecoverable)

        wait(for: [errorExp], timeout: 3)

        XCTAssertEqual(isRecoverable, sseClient.connectCalled)
        XCTAssertFalse(expSseAvailable)
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .keepAlive))
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .refreshAuthToken))
    }

    func testOnMessageReceived() {
        // When keep alive is received, keep alive timer should
        // be rescheduled
        let exp = XCTestExpectation(description: "finish")
        connectionManager.availabilityHandler = { isEnabled in
            exp.fulfill()
        }

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [successConnResult()]

        connectionManager.start()

        wait(for: [exp], timeout: 3)

        timersManager.reset()

        let values = [
            "f1":"v1",
            "f2":"v1",
            "f3":"v1"
        ]
        sseClient.fireOnMessage(values: values)

        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
    }

    // TODO: Test error messages sent by streaming provider
    func testOnMessageStreamingErrorReceived() {
    }

    override func tearDown() {
    }

    private func successAuthResult(pushEnabled: Bool = true) -> SseAuthenticationResult {
        return SseAuthenticationResult(success: true, errorIsRecoverable: false,
                                       pushEnabled: pushEnabled, jwtToken: dummyToken())
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
