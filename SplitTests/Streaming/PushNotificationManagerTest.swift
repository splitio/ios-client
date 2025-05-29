//
//  PushNotificationManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PushNotificationManagerTest: XCTestCase {
    var pnManager: PushNotificationManager!
    var sseAuthenticator: SseAuthenticatorStub!
    var timersManager: TimersManagerMock!
    var broadcasterChannel: SyncEventBroadcasterStub!
    let userKey = IntegrationHelper.dummyUserKey
    let key = Key(matchingKey: IntegrationHelper.dummyUserKey)
    var jwtParser: JwtTokenParser!
    let rawToken = "the_token"
    var telemetryProducer: TelemetryStorageStub!
    var byKeyFacade: ByKeyFacadeMock!
    var sseClientFactory: SseClientFactoryStub!

    override func setUp() {
        sseAuthenticator = SseAuthenticatorStub()
        timersManager = TimersManagerMock()
        broadcasterChannel = SyncEventBroadcasterStub()
        telemetryProducer = TelemetryStorageStub()
        byKeyFacade = ByKeyFacadeMock()
        let byKeyGroup = ByKeyComponentGroup(
            splitClient: SplitClientStub(),
            eventsManager: SplitEventsManagerStub(),
            mySegmentsSynchronizer: MySegmentsSynchronizerStub(),
            attributesStorage: ByKeyAttributesStorageStub(
                userKey: userKey,
                attributesStorage: AttributesStorageStub()))
        byKeyFacade.append(byKeyGroup, forKey: key)

        sseClientFactory = SseClientFactoryStub()

        let sseConnectionHandler = SseConnectionHandler(sseClientFactory: sseClientFactory)

        pnManager = DefaultPushNotificationManager(
            userKeyRegistry: byKeyFacade,
            sseAuthenticator: sseAuthenticator,
            broadcasterChannel: broadcasterChannel,
            timersManager: timersManager,
            telemetryProducer: telemetryProducer,
            sseConnectionHandler: sseConnectionHandler)
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

        broadcasterChannel.pushExpectationTriggerCallCount = 2
        broadcasterChannel.pushExpectation = exp
        sseAuthenticator.results = [successAuthResult()]

        addSseClient(connected: false, results: [true])

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClientFactory.clients[0].token)
        XCTAssertEqual(2, sseClientFactory.clients[0].channels?.count)
        XCTAssertNotNil(broadcasterChannel.pushedEvents.filter { $0 == .pushDelayReceived(delaySeconds: 0) }.count)
        XCTAssertEqual(SyncStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
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

        addSseClient(connected: false, results: [true])

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertFalse(sseClientFactory.clients[0].connectCalled)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect)) // ??
        XCTAssertEqual(SyncStatusEvent.pushRetryableError, broadcasterChannel.lastPushedEvent)
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
        broadcasterChannel.pushExpectationTriggerCallCount = 1
        sseAuthenticator.results = [successAuthResult()]
        addSseClient(connected: false, results: [false])

        pnManager.start()

        wait(for: [exp], timeout: 3)

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClientFactory.clients[0].token)
        XCTAssertEqual(2, sseClientFactory.clients[0].channels?.count)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertEqual(1, broadcasterChannel.pushedEvents.count)
        XCTAssertNotNil(broadcasterChannel.pushedEvents.filter { $0 == .pushDelayReceived(delaySeconds: 0) }.count)
    }

    func testStreamingDisabled() {
        // When auth endpoint responds with streaming disabled
        // Streaming will be turned off,
        // so this component should notify that streaming is not available,
        // cancel all timers and shutdown sse client
        let exp = XCTestExpectation(description: "finish")
        broadcasterChannel.pushExpectation = exp

        sseAuthenticator.results = [successAuthResult(pushEnabled: false)]
        addSseClient(connected: false, results: [true])

        pnManager.start()

        wait(for: [exp], timeout: 3)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertNil(sseClientFactory.clients[0].token)
        XCTAssertFalse(sseClientFactory.clients[0].disconnectCalled)
        XCTAssertFalse(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertEqual(SyncStatusEvent.pushSubsystemDisabled, broadcasterChannel.lastPushedEvent)

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

        let closeExp = XCTestExpectation()
        sseAuthenticator.results = [successAuthResult()]
        addSseClient(connected: true, results: [true], closeExp: closeExp)

        pnManager.start()

        wait(for: [conExp], timeout: 3)

        pnManager.stop()

        wait(for: [closeExp], timeout: 5)

        XCTAssertTrue(sseClientFactory.clients[0].disconnectCalled)
        XCTAssertTrue(timersManager.timerIsCancelled(timer: .refreshAuthToken))
    }

    func testResetConnectionOk() {
        pnManager.jwtParser = JwtParserStub(token: dummyToken())

        var exp = XCTestExpectation(description: "start")

        broadcasterChannel.pushExpectation = exp
        sseAuthenticator.results = [successAuthResult(), successAuthResult()]
        addSseClient(connected: false, results: [true])
        addSseClient(connected: false, results: [true])

        pnManager.start()

        wait(for: [exp], timeout: 3)

        exp = XCTestExpectation(description: "reset")
        broadcasterChannel.pushExpectationCallCount = 0
        broadcasterChannel.pushExpectationTriggerCallCount = 2
        broadcasterChannel.pushExpectation = exp

        telemetryProducer.streamingEvents = [:]
        timersManager.reset()
        pnManager.reset()

        wait(for: [exp], timeout: 10)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertTrue(sseClientFactory.clients[0].disconnectCalled)
        XCTAssertEqual(userKey, sseAuthenticator.userKeys[0])
        XCTAssertEqual(rawToken, sseClientFactory.clients[0].token)
        XCTAssertEqual(rawToken, sseClientFactory.clients[1].token)
        XCTAssertEqual(2, sseClientFactory.clients[0].channels?.count)
        XCTAssertEqual(2, sseClientFactory.clients[1].channels?.count)
        XCTAssertEqual(SyncStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
        XCTAssertTrue(timersManager.timerIsAdded(timer: .refreshAuthToken))
        XCTAssertFalse(timersManager.timerIsAdded(timer: .appHostBgDisconnect))
        XCTAssertNotNil(streamEvents[.tokenRefresh])
        XCTAssertNotNil(streamEvents[.connectionStablished])
    }

    private func successAuthResult(pushEnabled: Bool = true) -> SseAuthenticationResult {
        return SseAuthenticationResult(
            success: true,
            errorIsRecoverable: false,
            pushEnabled: pushEnabled,
            rawToken: rawToken,
            sseConnectionDelay: 0)
    }

    private func recoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(
            success: false,
            errorIsRecoverable: true,
            pushEnabled: true,
            rawToken: nil,
            sseConnectionDelay: 0)
    }

    private func noRecoverableAuthResult() -> SseAuthenticationResult {
        return SseAuthenticationResult(
            success: false,
            errorIsRecoverable: false,
            pushEnabled: true,
            rawToken: nil,
            sseConnectionDelay: 0)
    }

    private func dummyToken() -> JwtToken {
        return JwtToken(issuedAt: 1000, expirationTime: 10000, channels: ["ch1", "ch2"], rawToken: rawToken)
    }

    private func addSseClient(connected: Bool, results: [Bool], closeExp: XCTestExpectation? = nil) {
        let sseClient = SseClientMock(connected: connected)
        sseClient.results = results
        sseClient.closeExp = closeExp
        sseClientFactory.clients.append(sseClient)
    }
}
