//
//  PushNotificationManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PushNotificationManagerTest: XCTestCase {

    var pnManager: PushNotificationManager!
    var sseAuthenticator: SseAuthenticatorStub!
    var sseClient: SseClientMock!
    var timersManager: TimersManagerMock!
    var broadcasterChannel: PushManagerEventBroadcasterStub!
    let userKey = IntegrationHelper.dummyUserKey
    let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
    var jwtParser: JwtTokenParser!
    let rawToken = "the_token"
    var telemetryProducer: TelemetryStorageStub!
    var byKeyFacade: ByKeyFacadeStub!

    override func setUp() {
        sseAuthenticator = SseAuthenticatorStub()
        sseClient = SseClientMock()
        sseClient.isConnectionOpened = false
        timersManager = TimersManagerMock()
        broadcasterChannel = PushManagerEventBroadcasterStub()
        telemetryProducer = TelemetryStorageStub()
        byKeyFacade = ByKeyFacadeStub()
        let byKeyGroup = ByKeyComponentGroup(splitClient: SplitClientStub(),
                                             eventsManager: SplitEventsManagerStub(),
                                             mySegmentsSynchronizer: MySegmentsSynchronizerStub(),
                                             attributesStorage: ByKeyAttributesStorageStub(userKey: userKey,
                                                                                           attributesStorage: AttributesStorageStub()))
        byKeyFacade.append(byKeyGroup, forKey: key)
        pnManager = DefaultPushNotificationManager(userKeyRegistry: byKeyFacade, sseAuthenticator: sseAuthenticator,
                                                   sseClient: sseClient,broadcasterChannel: broadcasterChannel,
                                                   timersManager: timersManager, telemetryProducer: telemetryProducer)
    }

    func testStartFullConnectionOk() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels
        // Returning ok token with streaming enabled
        // Also an expectation is added to be fullfiled when timer is added
        // in order to avoid using sleep to wait for all process finished
        pnManager.jwtParser = JwtParserStub(token: dummyToken())

        let exp = XCTestExpectation(description: "finish")

        broadcasterChannel.pushExpectation = exp
        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [true]

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertEqual(PushStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertNotNil(streamEvents[.tokenRefresh])
        XCTAssertNotNil(streamEvents[.connectionStablished])
    }

    func testStartAuthReintent() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels
        // Returning ok token with streaming enabled
        // Also an expectation is added to be fullfiled when timer is added
        // in order to avoid using sleep to wait for all process finished

        let exp = XCTestExpectation(description: "finish")
        broadcasterChannel.pushExpectation = exp
        // Indicates that expectation have to be fired when push function is called the second time
        broadcasterChannel.pushExpectationTriggerCallCount = 1
        sseAuthenticator.results = [recoverableAuthResult()]

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertFalse(sseClient.connectCalled)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect)) // ??
        XCTAssertEqual(PushStatusEvent.pushRetryableError, broadcasterChannel.lastPushedEvent)
        XCTAssertNil(streamEvents[.tokenRefresh])
        XCTAssertNil(streamEvents[.connectionStablished])
        XCTAssertNil(streamEvents[.connectionError]) // To check that no recoverable error is recorded
    }

    func testStartSseReintent() {
        // On start connection manager
        // calls authenticate with user key
        // and then sse client with jwt raw token and channels
        // Calling success handler when streaming enabled
        // Also an expectation is added to be fullfiled when timer is added
        // in order to avoid using sleep to wait for all process finished
        pnManager.jwtParser = JwtParserStub(token: dummyToken())
        let exp = XCTestExpectation(description: "finish")
        broadcasterChannel.pushExpectation = exp
        // Indicates that expectation have to be fired when push function is called the second time
        broadcasterChannel.pushExpectationTriggerCallCount = 1
        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [false]

        pnManager.start()

        sleep(1)

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertNil(broadcasterChannel.lastPushedEvent)
    }

    func testStreamingDisabled() {
        // When auth endpoint responds with streaming disabled
        // Streaming will be turned off,
        // so this component should notify that streaming is not available,
        // cancel all timers and shutdown sse client
        let exp = XCTestExpectation(description: "finish")
        broadcasterChannel.pushExpectation = exp

        sseAuthenticator.results = [successAuthResult(pushEnabled: false)]

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertNil(sseClient.token)
        XCTAssertFalse(sseClient.disconnectCalled)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertEqual(PushStatusEvent.pushSubsystemDisabled, broadcasterChannel.lastPushedEvent)

        XCTAssertNil(streamEvents[.tokenRefresh])
        XCTAssertNil(streamEvents[.connectionStablished])
        XCTAssertNil(streamEvents[.connectionError]) // To check that no recoverable error is recorded
    }

    func testStop() {
        // On stop the component should close sse connection
        // stops keep alive and refresh token timers
        // and notify streaming not available
        pnManager.jwtParser = JwtParserStub(token: dummyToken())
        let conExp = XCTestExpectation(description: "conn")
        broadcasterChannel.pushExpectationTriggerCallCount = 1
        broadcasterChannel.pushExpectation = conExp

        sseAuthenticator.results = [successAuthResult()]
        sseClient.results = [true]

        pnManager.start()

        wait(for: [conExp], timeout: 3)

        pnManager.stop()

        //wait(for: [stopExp], timeout: 3)

        XCTAssertTrue(sseClient.disconnectCalled)
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .refreshAuthToken))
    }

    func testResetConnectionOk() {

        pnManager.jwtParser = JwtParserStub(token: dummyToken())

        var exp = XCTestExpectation(description: "start")

        broadcasterChannel.pushExpectation = exp
        sseAuthenticator.results = [successAuthResult(), successAuthResult()]
        sseClient.results = [true, true]

        pnManager.start()

        wait(for: [exp], timeout: 3)

        exp = XCTestExpectation(description: "reset")
        broadcasterChannel.pushExpectationTriggerCallCount = 2
        broadcasterChannel.pushExpectation = exp

        telemetryProducer.streamingEvents = [:]
        timersManager.reset()
        pnManager.reset()

        wait(for: [exp], timeout: 5)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertTrue(sseClient.disconnectCalled)
        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClient.token)
        XCTAssertEqual(2, sseClient.channels?.count)
        XCTAssertEqual(PushStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertNotNil(streamEvents[.tokenRefresh])
        XCTAssertNotNil(streamEvents[.connectionStablished])
    }

    override func tearDown() {
    }

    private func successAuthResult(pushEnabled: Bool = true) -> SseAuthenticationResult {
        return SseAuthenticationResult(success: true, errorIsRecoverable: false,
                                       pushEnabled: pushEnabled, rawToken: rawToken, sseConnectionDelay: 0)
    }

    private func recoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(success: false, errorIsRecoverable: true,
                                       pushEnabled: true, rawToken: nil, sseConnectionDelay: 0)
    }

    private func noRecoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(success: false, errorIsRecoverable: false,
                                       pushEnabled: true, rawToken: nil, sseConnectionDelay: 0)
    }

    private func dummyToken() -> JwtToken {
        return JwtToken(issuedAt: 1000, expirationTime: 10000, channels: ["ch1", "ch2"], rawToken:rawToken)
    }

}
