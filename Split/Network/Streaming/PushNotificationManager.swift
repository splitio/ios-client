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
    private let connectionQueue = DispatchQueue(label: "Sse connnection")
    private let stateQueue = DispatchQueue(label: "Sse state")

    private var lastJwtToken: JwtToken?

    private var state: State {
        stateQueue.sync {
            return self.currentState
        }
    }

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
        timersManager.cancel(timer: .refreshAuthToken)
        timersManager.cancel(timer: .appHostBgDisconnect)
        sseClient.disconnect()
        broadcasterChannel.push(event: .pushSubsystemDown)
        set(state: .stopped)
    }

    func pause() {
        // TODO: Add logic to handle background, foreground.
    }

    func resume() {
        // TODO: Add logic to handle background, foreground.
    }

    // MARK: Private
    private func set(state: State) {
        stateQueue.sync {
            self.currentState = state
        }
    }

    private func connect() {
        connectionQueue.async {
            while self.state != .stopped && self.state != .connected {
                if let jwt = self.authenticateToSse(), self.connectToSse(jwt: jwt) {
                    return
                }
                if self.state == .stopped {
                    return
                }
                self.delay(seconds: self.sseBackoffCounter.getNextRetryTime())
            }
        }
    }

    private func authenticateToSse() -> JwtToken? {
        set(state: .authenticating)

        let result = sseAuthenticator.authenticate(userKey: userKey)
        if result.success && !result.pushEnabled {
            broadcasterChannel.push(event: .pushSubsystemDown)
            set(state: .stopped)
            return nil
        }

        if !result.success && !result.errorIsRecoverable {
            broadcasterChannel.push(event: .pushNonRetryableError)
            set(state: .disconnected)
            return nil
        }

        if result.success, let jwtToken = result.jwtToken {
            return jwtToken
        }

        set(state: .disconnected)
        broadcasterChannel.push(event: .pushRetryableError)
        return nil
    }

    private func connectToSse(jwt: JwtToken) -> Bool {
        // This function must be called
        // from an async queue

        set(state: .connecting)
        lastJwtToken = jwt
        let result = sseClient.connect(token: jwt.rawToken, channels: jwt.channels)
        if result.success {
            set(state: .connected)
            timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
            sseBackoffCounter.resetCounter()
            broadcasterChannel.push(event: .pushSubsystemUp)
            return true
        }

        broadcasterChannel.push(event: result.errorIsRecoverable ? .pushRetryableError : .pushNonRetryableError)
        return false
    }

    private func delay(seconds: Double) {
        // Using this method to avoid blocking the
        // thread using sleep
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds) {
            semaphore.signal()
        }
        semaphore.wait()
    }
}
