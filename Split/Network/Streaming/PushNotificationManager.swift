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
        sseClient.disconnect()
    }

    func resume() {
        Logger.d("Push notification manager resumed")
        isPaused.set(false)
        if isStopped.value || sseClient.isConnectionOpened || isConnecting.value {
            return
        }
        connect()
    }

    func stop() {
        isStopped.set(true)
        timersManager.cancel(timer: .refreshAuthToken)
        timersManager.cancel(timer: .appHostBgDisconnect)
        sseClient.disconnect()
    }

    private func connect() {
        if isStopped.value || isPaused.value || isConnecting.value {
            return
        }
        isConnecting.set(true)
        connectionQueue.async {
            self.connectToSse()
        }
    }

    private func connectToSse() {

        let result = sseAuthenticator.authenticate(userKey: userKey)
        if result.success && !result.pushEnabled {
            Logger.d("Streaming disabled for api key")
            broadcasterChannel.push(event: .pushSubsystemDisabled)
            isStopped.set(true)
            return
        }

        if !result.success && !result.errorIsRecoverable {
            Logger.d("Streaming client error. Please check your API key")
            isStopped.set(true)
            broadcasterChannel.push(event: .pushNonRetryableError)
            return
        }

        if !result.success && result.errorIsRecoverable {
            Logger.d("Streaming auth error. Retrying")
            broadcasterChannel.push(event: .pushRetryableError)
            return
        }

        guard let jwt = result.jwtToken else {
            return
        }
        Logger.d("Streaming authentication success")

        if isStopped.value {
            Logger.d("Streaming stopped. Aborting connection")
            return
        }
        self.sseClient.connect(token: jwt.rawToken, channels: jwt.channels) { success in
            if success {
                self.handleSubsystemUp()
            }
            self.isConnecting.set(false)
        }
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
            case .appHostBgDisconnect:
                // This should be called only if bg capabilities are
                // enabled, so if not paused the timer has been fired
                // when app is running. In this case it should be ignored
                if self.isPaused.value {
                    Logger.d("Disconnecting SSE client while in background")
                    self.timersManager.cancel(timer: .refreshAuthToken)
                    self.sseClient.disconnect()
                }
            }
        }
    }
}
