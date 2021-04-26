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

    private let connectionQueue = DispatchQueue(label: "Sse connnection", target: DispatchQueue.global())

    private var isStopped: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)
    private var isConnecting: Atomic<Bool> = Atomic(false)

    var jwtParser: JwtTokenParser = DefaultJwtTokenParser()

    init(userKey: String, sseAuthenticator: SseAuthenticator, sseClient: SseClient,
         broadcasterChannel: PushManagerEventBroadcaster, timersManager: TimersManager) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.broadcasterChannel = broadcasterChannel
        self.timersManager = timersManager
        self.timersManager.triggerHandler = timerHandler()
    }

    // MARK: Public
    func start() {
        connect()
    }

    func pause() {
        Logger.d("Push notification manager paused")
        isPaused.set(true)
        isConnecting.set(false)
        sseClient.disconnect()
    }

    func resume() {
        Logger.d("Push notification manager resumed")
        isPaused.set(false)
        connect()
    }

    func stop() {
        isStopped.set(true)
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

        if isStopped.value {
            Logger.d("Streaming stopped. Aborting connection")
            isConnecting.set(false)
            return
        }
        Logger.d("Streaming authentication success")

        self.sseClient.connect(token: jwt.rawToken, channels: jwt.channels) { success in
            if success {
                self.handleSubsystemUp()
            }
            self.isConnecting.set(false)
        }
    }

    private func notifyRecoverableError(message: String) {
        Logger.d(message)
        isConnecting.set(false)
        broadcasterChannel.push(event: .pushRetryableError)
    }

    private func handleSubsystemUp() {
        self.timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
        self.broadcasterChannel.push(event: .pushSubsystemUp)
    }

    private func timerHandler() -> TimersManager.TimerHandler {
        return { timerName in
            switch timerName {
            case .refreshAuthToken:
                self.sseClient.disconnect()
                self.connect()
            default:
                Logger.d("No handler or timer: \(timerName)")
            }
        }
    }
}
