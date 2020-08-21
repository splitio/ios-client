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
        case stopped
    }

    var availabilityHandler: AvailabilityHandler?
    private let kSseKeepAliveTimeInSeconds = 70
    private let kReconnectTimeBeforeTokenExpInASeconds = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var sseClient: SseClient
    private let authBackoffCounter: ReconnectBackoffCounter
    private let sseBackoffCounter: ReconnectBackoffCounter
    private let timersManager: TimersManager
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
         authBackoffCounter: ReconnectBackoffCounter,
         sseBackoffCounter: ReconnectBackoffCounter, timersManager: TimersManager) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.authBackoffCounter = authBackoffCounter
        self.sseBackoffCounter = sseBackoffCounter
        self.timersManager = timersManager
        self.currentState = .disconnected
        setupSseClient()
    }

    // MARK: Public
    func start() {
        connect()
    }

    func stop() {
        timersManager.cancel(timer: .keepAlive)
        timersManager.cancel(timer: .refreshAuthToken)
        sseClient.disconnect()
        reportStreaming(isAvailable: false)
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
            if let jwt = self.authenticateToSse() {
                self.connectToSse(jwt: jwt)
            }
        }
    }

    private func authenticateToSse() -> JwtToken? {
        set(state: .authenticating)

        while true && state != .stopped {
            let result = sseAuthenticator.authenticate(userKey: userKey)
            if (result.success && !result.pushEnabled) ||
                (!result.success && !result.errorIsRecoverable) {
                reportStreaming(isAvailable: false)
                set(state: .disconnected)
                // shutdown streaming
                return nil
            }

            if result.success, let jwtToken = result.jwtToken {
                authBackoffCounter.resetCounter()
                return jwtToken
            }
            reportStreaming(isAvailable: false)
            delay(seconds: authBackoffCounter.getNextRetryTime())
        }
        return nil
    }

    private func connectToSse(jwt: JwtToken) {
        // This function must be called
        // from an async queue
        while true && state != .stopped {
            set(state: .connecting)
            lastJwtToken = jwt
            let result = sseClient.connect(token: jwt.rawToken, channels: jwt.channels)
            if result.success {
                set(state: .connected)
                reportStreaming(isAvailable: true)
                timersManager.add(timer: .keepAlive, delayInSeconds: kSseKeepAliveTimeInSeconds)
                timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
                sseBackoffCounter.resetCounter()
                return
            }
            reportStreaming(isAvailable: false)
            delay(seconds: sseBackoffCounter.getNextRetryTime())
        }
    }

    private func reportStreaming(isAvailable: Bool) {
        if let handler = availabilityHandler {
            handler(isAvailable)
        }
    }

    private func setupSseClient() {

        sseClient.onMessageHandler = {  [weak self] message in
            guard let self = self else {
                return
            }
            self.timersManager.add(timer: .keepAlive, delayInSeconds: self.kSseKeepAliveTimeInSeconds)
            // TODO: Add logic to handle error messages when stream error messages parser implemented
        }

        sseClient.onKeepAliveHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.timersManager.add(timer: .keepAlive, delayInSeconds: self.kSseKeepAliveTimeInSeconds)
        }

        sseClient.onErrorHandler = { [weak self] isRecoverable in
            guard let self = self else {
                return
            }
            self.handleOnError(isRecoverable: isRecoverable)
        }
    }

    private func handleOnError(isRecoverable: Bool) {
        set(state: .disconnected)
        timersManager.cancel(timer: .keepAlive)
        timersManager.cancel(timer: .refreshAuthToken)
        reportStreaming(isAvailable: false)
        if isRecoverable {
            connect()
        }
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
