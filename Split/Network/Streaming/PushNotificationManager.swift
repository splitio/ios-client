//
//  SseConnectionManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PushNotificationManager {
    func start()
    func stop()
    func pause()
    func resume()
}

class DefaultPushNotificationManager: PushNotificationManager {

    private enum State {
        case disconnected
        case authenticating
        case authenticated
        case connecting
        case connected
        case stopped
    }

    private let kSseKeepAliveTimeInSeconds = 70
    private let kReconnectTimeBeforeTokenExpInASeconds = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var sseClient: SseClient
    private let sseBackoffCounter: ReconnectBackoffCounter
    private let timersManager: TimersManager
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let userKey: String
    private var currentState: State
    private let connectionQueue = DispatchQueue(label: "Sse connnection", target: DispatchQueue.global())

    private var lastJwtToken: JwtToken?

    private var state: Atomic<State> = Atomic(.disconnected)

    init(userKey: String, sseAuthenticator: SseAuthenticator, sseClient: SseClient,
         sseBackoffCounter: ReconnectBackoffCounter,
         broadcasterChannel: PushManagerEventBroadcaster, timersManager: TimersManager) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.sseBackoffCounter = sseBackoffCounter
        self.broadcasterChannel = broadcasterChannel
        self.timersManager = timersManager
        self.currentState = .disconnected
    }

    // MARK: Public
    func start() {
        connect()
    }

    func stop() {
        state.set(.stopped)
        timersManager.cancel(timer: .refreshAuthToken)
        timersManager.cancel(timer: .appHostBgDisconnect)
        sseClient.disconnect()
        broadcasterChannel.push(event: .pushSubsystemDown)
    }

    func pause() {
        // TODO: Add logic to handle background, foreground.
    }

    func resume() {
        // TODO: Add logic to handle background, foreground.
    }

    private func connect() {
        connectionQueue.async {
            while !([State.stopped, State.connected].contains(self.state.value)) {
                if let jwt = self.authenticateToSse(), self.connectToSse(jwt: jwt) {
                    return
                }
                if self.state.value == .stopped {
                    return
                }
                ThreadUtils.delay(seconds: self.sseBackoffCounter.getNextRetryTime())
            }
        }
    }

    private func authenticateToSse() -> JwtToken? {

        // If status has changed to stopped
        // then stop the process.
        if state.getAndSet(.authenticating) == .stopped {
            state.set(.stopped)
            return nil
        }

        let result = sseAuthenticator.authenticate(userKey: userKey)
        if result.success && !result.pushEnabled {
            Logger.d("Streaming disabled for api key")
            broadcasterChannel.push(event: .pushSubsystemDown)
            state.set(.stopped)
            return nil
        }

        if !result.success && !result.errorIsRecoverable {
            Logger.d("Streaming auth error. Retrying.")
            broadcasterChannel.push(event: .pushNonRetryableError)
            state.set(.stopped)
            return nil
        }

        if result.success, let jwtToken = result.jwtToken, state.getAndSet(.authenticated) != .stopped {
            Logger.d("Streaming authentication success.")
            return jwtToken
        }

        if state.getAndSet(.disconnected) == .stopped {
            state.set(.stopped)
            return nil
        }
        broadcasterChannel.push(event: .pushRetryableError)
        return nil
    }

    private func connectToSse(jwt: JwtToken) -> Bool {

        if state.getAndSet(.connecting) == .stopped {
            state.set(.stopped)
            return false
        }

        lastJwtToken = jwt
        let result = sseClient.connect(token: jwt.rawToken, channels: jwt.channels)
        if result.success, state.getAndSet(.connected) != .stopped {
            timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
            sseBackoffCounter.resetCounter()
            broadcasterChannel.push(event: .pushSubsystemUp)
            return true
        }

        if state.value == .stopped {
            return false
        }

        broadcasterChannel.push(event: result.errorIsRecoverable ? .pushRetryableError : .pushNonRetryableError)
        return false
    }
}
