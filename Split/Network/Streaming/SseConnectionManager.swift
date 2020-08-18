//
//  SseConnectionManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseConnectionManager {
    func start()
    func stop()
    func pause()
    func resume()
    func availabilityHandler(streamingEnabled: Bool)
}

class DefaultSseConnectionManager: SseConnectionManager {

    private enum State {
        case disconnected
        case authenticating
        case connecting
        case connected
    }

    private static let kSseKeepAliveTimeInSeconds = 70
    private static let kReconnectTimeBeforeTokenExpInASeconds = 600
    private static let kDisconnectOnBgTimeInSeconds = 60
    private static let kTokenExpiredErrorCode = 40142

    private let sseAuthenticator: SseAuthenticator
    private let sseClient: SseClient
    private let authBackoffCounter: ReconnectBackoffCounter
    private let sseBackoffCounter: ReconnectBackoffCounter
    private let timersManager: TimersManager
    private var currentState: State
    private var connectionQueue = DispatchQueue(label: "Sse connnection")

    init(userKey: String, sseAuthenticator: SseAuthenticator, sseClient: SseClient,
         authBackoffCounter: ReconnectBackoffCounter,
         sseBackoffCounter: ReconnectBackoffCounter, timersManager: TimersManager) {
        self.sseAuthenticator = sseAuthenticator
        self.sseClient = sseClient
        self.authBackoffCounter = authBackoffCounter
        self.sseBackoffCounter = sseBackoffCounter
        self.timersManager = timersManager
        self.currentState = .disconnected
    }

    // MARK: Public
    func start() {
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
}
