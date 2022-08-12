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
    private let kReconnectTimeBeforeTokenExpInASeconds = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var sseClient: SseClient?
    private var sseClientFactory: SseClientFactory
    private var timersManager: TimersManager
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let userKeyRegistry: ByKeyRegistry
    private let sseConnectionTimer: DispatchSourceTimer? = nil

    private var lastConnId: Int64 = 0

    private let connectionQueue = DispatchQueue(label: "Sse connnection",
                                                attributes: .concurrent)

    private var isStopped: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)
    private var isConnecting: Atomic<Bool> = Atomic(false)

    var jwtParser: JwtTokenParser = DefaultJwtTokenParser()

    private var delayTimer: DispatchWorkItem?

    private let telemetryProducer: TelemetryRuntimeProducer?

    init(userKeyRegistry: ByKeyRegistry,
         sseAuthenticator: SseAuthenticator,
         sseClientFactory: SseClientFactory,
         broadcasterChannel: PushManagerEventBroadcaster,
         timersManager: TimersManager,
         telemetryProducer: TelemetryRuntimeProducer?) {
        self.userKeyRegistry = userKeyRegistry
        self.sseAuthenticator = sseAuthenticator
        self.broadcasterChannel = broadcasterChannel
        self.telemetryProducer = telemetryProducer
        self.timersManager = timersManager
        self.sseClientFactory = sseClientFactory
        self.timersManager.triggerHandler = timerHandler()
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
        delayTimer?.cancel()
        if let disconnectingClient = sseClient {
            DispatchQueue.global().async {
                disconnectingClient.disconnect()
            }
        }
        isConnecting.set(false)
    }

    private func connect() {
        if isStopped.value || isPaused.value ||
            isConnecting.value || sseClient?.isConnectionOpened ?? false {
            return
        }

        connectionQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.isConnecting.set(true)
            self.authenticateAndConnect()
        }
    }

    // This method must run within connectionQueue!!
    private func authenticateAndConnect() {
        lastConnId = Date().unixTimestampInMicroseconds()
        let result = sseAuthenticator.authenticate(userKeys: userKeyRegistry.matchingKeys.map { $0 })
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
        let lastId = lastConnId
        if connectionDelay > 0 {
            let delaySem = DispatchSemaphore(value: 0)
            let delayTimer = DispatchWorkItem {
                delaySem.signal()
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + Double(connectionDelay),
                                              execute: delayTimer)
            delaySem.wait()
            if lastId != self.lastConnId { return }
            connectSse(jwt: jwt)
        } else {
            connectSse(jwt: jwt)
        }
    }

    // This method must run within connectionQueue!!
    private func connectSse(jwt: JwtToken) {
        Logger.d("Streaming connect")
        let sseClient = sseClientFactory.create()

        if isPaused.value || isStopped.value {
            isConnecting.set(false)
            return
        }

        sseClient.connect(token: jwt.rawToken, channels: jwt.channels) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.handleSubsystemUp()
            }
            self.telemetryProducer?.recordStreamingEvent(type: .connectionStablished,
                                                         data: nil)
            self.isConnecting.set(false)
        }
        self.sseClient = sseClient
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
                self.telemetryProducer?.recordStreamingEvent(type: .connectionError,
                                                        data: TelemetryStreamingEventValue.sseConnErrorRequested)
                self.reset()
            default:
                Logger.d("No handler or timer: \(timerName)")
            }
        }
    }
}
