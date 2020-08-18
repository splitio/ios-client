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
    let sseAuthenticator = SseAuthenticatorStub()
    let sseClient = SseClientMock()
    let authBackoff = ReconnectBackoffCounterStub()
    let sseBackoff = ReconnectBackoffCounterStub()
    let timersManager = TimersManagerMock()
    let userKey = IntegrationHelper.dummyUserKey

    override func setUp() {
        connectionManager = DefaultSseConnectionManager(userKey: userKey, sseAuthenticator: sseAuthenticator, sseClient: sseClient, authBackoffCounter: authBackoff,
                                                        sseBackoffCounter: sseBackoff, timersManager: timersManager)

    }

    func testStartFullConnectionOk() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels

        // Returning ok token with streaming enabled
        sseAuthenticator.result = SseAuthenticationResult(success: true, errorIsRecoverable: false, pushEnabled: true, jwtToken: dummyToken())

        connectionManager.start()

        XCTAssertEqual(userKey, sseAuthenticator.userKey)
        XCTAssertEqual("thetoken", sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .authRecconect))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .sseReconnect))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refresahAuthToken))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertTrue(timersManager.timerIsAdded(timer: .keepAlive))
    }

    override func tearDown() {

    }

    private func dummyToken() -> JwtToken {
        return JwtToken(issuedAt: 1000, expirationTime: 10000, channels: ["ch1", "ch2"], rawToken: "thetoken")
    }

}
