//
//  SseConnectionManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PushNotificationManager {
    // Visible for testing. Make possible to inject stub
    var jwtParser: JwtTokenParser { get set }
    func start()
    func pause()
    func resume()
    func stop()
    func disconnect()
    func reset()
}

class DefaultPushNotificationManager: PushNotificationManager {

    private let kSseKeepAliveTimeInSeconds = 70
    private let kReconnectTimeBeforeTokenExpInASeconds: Int64 = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var timersManager: TimersManager
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let userKeyRegistry: ByKeyRegistry

    private let lastConnId = Atomic<Int64>(-1)

    private let connectionQueue = DispatchQueue(label: "Sse connnection",
                                                attributes: .concurrent)

    private var isStopped: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)
    private var isConnecting: Atomic<Bool> = Atomic(false)

    var jwtParser: JwtTokenParser = DefaultJwtTokenParser()

    private let telemetryProducer: TelemetryRuntimeProducer?
    private let sseConnectionHandler: SseConnectionHandler

    init(userKeyRegistry: ByKeyRegistry,
         sseAuthenticator: SseAuthenticator,
         broadcasterChannel: PushManagerEventBroadcaster,
         timersManager: TimersManager,
         telemetryProducer: TelemetryRuntimeProducer?,
         sseConnectionHandler: SseConnectionHandler
    ) {
        self.userKeyRegistry = userKeyRegistry
        self.sseAuthenticator = sseAuthenticator
        self.broadcasterChannel = broadcasterChannel
        self.telemetryProducer = telemetryProducer
        self.timersManager = timersManager
        self.sseConnectionHandler = sseConnectionHandler
    }

    // MARK: Public
    func start() {
        connect()
    }

    func reset() {
        Logger.d("Push notification manager reset")
        disconnect()
        connect()
    }

    func pause() {
        Logger.d("Push notification manager paused")
        isPaused.set(true)
        disconnect()
    }

    func resume() {
        Logger.d("Push notification manager resumed")
        isPaused.set(false)
        connect()
    }

    func stop() {
        Logger.d("Push notification manager stopped")
        disconnect()
        broadcasterChannel.destroy()
        timersManager.destroy()
        isStopped.set(true)
    }

    func disconnect() {
        Logger.d("Notification Manager - Disconnecting SSE client")
        timersManager.cancel(timer: .refreshAuthToken)
        timersManager.cancel(timer: .streamingDelay)
        isConnecting.set(false)
        sseConnectionHandler.disconnect()
    }

    private func connect() {
        if isStopped.value || isPaused.value ||
            isConnecting.value || sseConnectionHandler.isConnectionOpened {
            return
        }

        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isConnecting.set(true)
            self.authenticateAndConnect()
        }
    }

    // This method must run within connectionQueue!!
    private func authenticateAndConnect() {
        lastConnId.set(Date().unixTimestampInMicroseconds())
        let result = sseAuthenticator.authenticate(userKeys: userKeyRegistry.matchingKeys.map { $0 })
        telemetryProducer?.recordLastSync(resource: .token, time: Date().unixTimestampInMiliseconds())

        if !isPushEnabled(result: result) { return }
        if isErrorNonRecoverable(result: result) { return }
        if isErrorRecoverable(result: result) { return }

        guard let jwt = extractJwt(result: result) else { return }

        telemetryProducer?.recordStreamingEvent(type: .tokenRefresh, data: jwt.expirationTime)

        if isStopped.value {
            Logger.d("Streaming stopped. Aborting connection")
            isConnecting.set(false)
            return
        }
        Logger.d("Streaming authentication success")

        let connectionDelay = result.sseConnectionDelay
        let lastId = lastConnId.value
        if connectionDelay > 0 {
            self.timersManager.cancel(timer: .streamingDelay)
            let delayTimer =  DefaultTask(delay: connectionDelay) { [weak self] in
                guard let self = self else { return }
                if lastId != self.lastConnId.value { return }
                self.connectSse(jwt: jwt)
            }
            self.timersManager.add(timer: .streamingDelay, task: delayTimer)

        } else {
            connectSse(jwt: jwt)
        }
    }

    // This methods must run within connectionQueue!!
    private func isPushEnabled(result: SseAuthenticationResult) -> Bool {
        if result.success && !result.pushEnabled {
            Logger.d("Streaming disabled for api key")
            isStopped.set(true)
            isConnecting.set(false)
            broadcasterChannel.push(event: .pushSubsystemDisabled)
            return false
        }
        return true
    }

    private func isErrorNonRecoverable(result: SseAuthenticationResult) -> Bool {
        if !result.success && !result.errorIsRecoverable {
            Logger.d("Streaming client error. Please check your API key")
            isStopped.set(true)
            isConnecting.set(false)
            broadcasterChannel.push(event: .pushNonRetryableError)
            telemetryProducer?.recordAuthRejections()
            return true
        }
        return false
    }

    private func isErrorRecoverable(result: SseAuthenticationResult) -> Bool {

        if !result.success && result.errorIsRecoverable {
            notifyRecoverableError(message: "Streaming auth error. Retrying")
            return true
        }
        return false
    }

    private func extractJwt(result: SseAuthenticationResult) -> JwtToken? {
        guard let rawToken = result.rawToken else {
            notifyRecoverableError(message: "Invalid raw JWT")
            return nil
        }

        guard let jwt = try? jwtParser.parse(raw: rawToken) else {
            notifyRecoverableError(message: "Error parsing JWT")
            return nil
        }
        return jwt
    }

    private func connectSse(jwt: JwtToken) {
        Logger.d("Streaming connect")

        if isPaused.value || isStopped.value {
            isConnecting.set(false)
            return
        }

        sseConnectionHandler.connect(jwt: jwt, channels: jwt.channels) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.handleSubsystemUp()
            }
            self.telemetryProducer?.recordStreamingEvent(type: .connectionStablished,
                                                         data: nil)
            self.isConnecting.set(false)
        }
    }

    private func notifyRecoverableError(message: String) {
        Logger.d(message)
        isConnecting.set(false)
        broadcasterChannel.push(event: .pushRetryableError)
    }

    private func handleSubsystemUp() {
        timersManager.add(timer: .refreshAuthToken, task: self.createRefreshTokenTask())
        broadcasterChannel.push(event: .pushSubsystemUp)
        telemetryProducer?.recordTokenRefreshes()
    }

    private func createRefreshTokenTask() -> CancellableTask {
        return DefaultTask(delay: kReconnectTimeBeforeTokenExpInASeconds) { [weak self] in
            guard let self = self else { return }
            self.telemetryProducer?.recordStreamingEvent(type: .connectionError,
                                                         data: TelemetryStreamingEventValue.sseConnErrorRequested)
            self.reset()
        }
    }
}
