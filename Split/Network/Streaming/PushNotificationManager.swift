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

    private let kSseKeepAliveTimeInSeconds = 70
    private let kReconnectTimeBeforeTokenExpInASeconds = 600
    private let kDisconnectOnBgTimeInSeconds = 60
    private let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private var sseClient: SseClient
    private let timersManager: TimersManager
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let userKey: String
    private let connectionQueue = DispatchQueue(label: "Sse connnection", target: DispatchQueue.global())

    private var isStopped: Atomic<Bool> = Atomic(false)

    init(userKey: String, sseAuthenticator: SseAuthenticator, sseClient: SseClient,
         broadcasterChannel: PushManagerEventBroadcaster, timersManager: TimersManager) {
        self.userKey = userKey
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.broadcasterChannel = broadcasterChannel
        self.timersManager = timersManager
    }

    // MARK: Public
    func start() {
        connect()
    }

    func stop() {
        isStopped.set(true)
        timersManager.cancel(timer: .refreshAuthToken)
        timersManager.cancel(timer: .appHostBgDisconnect)
        sseClient.disconnect()
    }

    func pause() {
        // TODO: Add logic to handle background, foreground.
    }

    func resume() {
        // TODO: Add logic to handle background, foreground.
    }

    private func connect() {
        if self.isStopped.value {
            return
        }
        connectionQueue.async {
            self.connectToSse()
        }
    }

    private func connectToSse() {

        let result = sseAuthenticator.authenticate(userKey: userKey)
        if result.success && !result.pushEnabled {
            Logger.d("Streaming disabled for api key")
            broadcasterChannel.push(event: .pushSubsystemDown)
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
        self.sseClient.connect(token: jwt.rawToken, channels: jwt.channels) {
            self.handleSubsystemUp()
        }
    }

    private func handleSubsystemUp() {
        self.timersManager.add(timer: .refreshAuthToken, delayInSeconds: kReconnectTimeBeforeTokenExpInASeconds)
        self.broadcasterChannel.push(event: .pushSubsystemUp)
    }
}
