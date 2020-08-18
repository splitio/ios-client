//
//  SseConnectionManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseConnectionManager {
    typealias AvailabilityHandler = (Bool) -> Void
    var availabilityHandler: AvailabilityHandler? { get set }
    func start()
    func stop()
    func pause()
    func resume()
}

class DefaultSseConnectionManager: SseConnectionManager {



    private enum State {
        case disconnected
        case authenticating
        case connecting
        case connected
    }

    var availabilityHandler: AvailabilityHandler?
    private static let kSseKeepAliveTimeInSeconds = 70
    private static let kReconnectTimeBeforeTokenExpInASeconds = 600
    private static let kDisconnectOnBgTimeInSeconds = 60
    private static let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private let sseClient: SseClient
    private let authBackoffCounter: ReconnectBackoffCounter
    private let sseBackoffCounter: ReconnectBackoffCounter
    private let timersManager: TimersManager
    private let userKey: String
    private var currentState: State
    private var connectionQueue = DispatchQueue(label: "Sse connnection")

    private var lastJwtToken: JwtToken?

    init(userKey: String, sseAuthenticator: SseAuthenticator, sseClient: SseClient,
         authBackoffCounter: ReconnectBackoffCounter,
         sseBackoffCounter: ReconnectBackoffCounter, timersManager: TimersManager) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.authBackoffCounter = authBackoffCounter
        self.sseBackoffCounter = sseBackoffCounter
        self.timersManager = timersManager
        self.currentState = .disconnected
    }

    // MARK: Public
    func start() {
        connect()
    }

    func stop() {
    }

    func pause() {
    }

    func resume() {
    }

    func availabilityHandler(streamingEnabled: Bool) {
    }

    // MARK: Private
    private func set(state: State) {
        connectionQueue.sync {
            self.currentState = state
        }
    }

    private func currentStatus() -> State {
        connectionQueue.sync {
            return self.currentState
        }
    }

    private func connect() {
        connectionQueue.async {
            self.set(state: .authenticating)

            var isAuthenticated = false
            var jwt: JwtToken?
            while !isAuthenticated {
                let result = self.sseAuthenticator.authenticate(userKey: self.userKey)
                if (result.success && !result.pushEnabled) ||
                    (!result.success && !result.errorIsRecoverable) {
                    self.reportStreaming(isAvailable: false)
                    self.set(state: .disconnected)
                    // shutdown streaming
                    return
                }

                if result.success, let jwtToken = result.jwtToken {
                    jwt = jwtToken
                    isAuthenticated = true
                    self.reportStreaming(isAvailable: true)
                } else {
                    self.reportStreaming(isAvailable: false)
                    self.delay(seconds: self.authBackoffCounter.getNextRetryTime())
                }
            }

            // jwt will never be null here
            if let jwt = jwt {
                self.set(state: .connecting)
                self.lastJwtToken = jwt
                self.sseClient.connect(token: jwt.rawToken, channels: jwt.channels)
            }
        }
    }

    private func reportStreaming(isAvailable: Bool) {
        if let handler = availabilityHandler {
            handler(isAvailable)
        }
    }

    private func delay(seconds: Double) {
        // Using this method to avoid blocking the
        // thread using sleep
        let semaphore = DispatchSemaphore(value: 0)
        connectionQueue.asyncAfter(deadline: .now() + seconds) {
            semaphore.signal()
        }
        semaphore.wait()
    }
}
