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
}

class DefaultPushNotificationManager: PushNotificationManager {

    private let kSseKeepAliveTimeInSeconds = 70
    private let kReconnectTimeBeforeTokenExpInASeconds = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var sseClient: SseClient
    private var timersManager: TimersManager
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let userKey: String
    private let sseConnectionTimer: DispatchSourceTimer? = nil

    private let connectionQueue = DispatchQueue(label: "Sse connnection",
                                                target: DispatchQueue.global())

    private var isStopped: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)
    private var isConnecting: Atomic<Bool> = Atomic(false)

    var jwtParser: JwtTokenParser = DefaultJwtTokenParser()

    var delayTimer: DelayTimer

    private let telemetryProducer: TelemetryRuntimeProducer?

    init(userKey: String, sseAuthenticator: SseAuthenticator,
         sseClient: SseClient, broadcasterChannel: PushManagerEventBroadcaster,
         timersManager: TimersManager, telemetryProducer: TelemetryRuntimeProducer?) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.broadcasterChannel = broadcasterChannel
        self.telemetryProducer = telemetryProducer
        self.timersManager = timersManager
        self.delayTimer = DefaultTimer()
        self.timersManager.triggerHandler = timerHandler()
    }

    // MARK: Public
    func start() {
        connect()
    }

    func pause() {
        Logger.d("Push notification manager paused")
        isPaused.set(true)
        delayTimer.cancel()
        isConnecting.set(false)
        sseClient.disconnect()
    }

    func resume() {
        Logger.d("Push notification manager resumed")
        isPaused.set(false)
        connect()
    }

    func stop() {
        Logger.d("Push notification manager stopped")
        isStopped.set(true)
        delayTimer.cancel()
        disconnect()
    }

    func disconnect() {
        Logger.d("Disconnecting SSE client")
        timersManager.cancel(timer: .refreshAuthToken)
        sseClient.disconnect()
    }

    private func connect() {
        if isStopped.value || isPaused.value ||
            isConnecting.value || sseClient.isConnectionOpened {
            return
        }

        connectionQueue.async {
            self.isConnecting.set(true)
            self.connectToSse()
        }
    }

    private func connectToSse() {

        let result = sseAuthenticator.authenticate(userKey: userKey)
        telemetryProducer?.recordLastSync(resource: .token, time: Date().unixTimestampInMiliseconds())
        if result.success && !result.pushEnabled {
            Logger.d("Streaming disabled for api key")
            isStopped.set(true)
            isConnecting.set(false)
            broadcasterChannel.push(event: .pushSubsystemDisabled)
            return
        }

        if !result.success && !result.errorIsRecoverable {
            Logger.d("Streaming client error. Please check your API key")
            isStopped.set(true)
            isConnecting.set(false)
            broadcasterChannel.push(event: .pushNonRetryableError)
            telemetryProducer?.recordAuthRejections()
            return
        }

        if !result.success && result.errorIsRecoverable {
            notifyRecoverableError(message: "Streaming auth error. Retrying")
            return
        }

        guard let rawToken = result.rawToken else {
            notifyRecoverableError(message: "Invalid raw JWT")
            return
        }

        guard let jwt = try? jwtParser.parse(raw: rawToken) else {
            notifyRecoverableError(message: "Error parsing JWT")
            return
        }

        telemetryProducer?.recordStreamingEvent(type: .tokenRefresh, data: jwt.expirationTime)

        if isStopped.value {
            Logger.d("Streaming stopped. Aborting connection")
            isConnecting.set(false)
            return
        }
        Logger.d("Streaming authentication success")

        let connectionDelay = result.sseConnectionDelay

        if connectionDelay > 0 && !delayTimer.delay(seconds: connectionDelay) {
            isConnecting.set(false)
            return
        }

        if isPaused.value || isStopped.value {
            isConnecting.set(false)
            return
        }

        Logger.d("Streaming connect")
        sseClient.connect(token: jwt.rawToken, channels: jwt.channels) { success in
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
        timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
        broadcasterChannel.push(event: .pushSubsystemUp)
        telemetryProducer?.recordTokenRefreshes()
    }

    private func timerHandler() -> TimersManager.TimerHandler {

        return { [weak self] timerName in
            guard let self = self else {
                return
            }

            switch timerName {
            case .refreshAuthToken:
                self.sseClient.disconnect()
                self.telemetryProducer?.recordStreamingEvent(type: .connectionError,
                                                        data: TelemetryStreamingEventValue.sseConnErrorRequested)
                self.connect()
            default:
                Logger.d("No handler or timer: \(timerName)")
            }
        }
    }
}
