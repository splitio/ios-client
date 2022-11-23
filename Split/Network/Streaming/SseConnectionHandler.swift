//
//  SseConnectionHandler.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Oct-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SseConnectionHandler {
    private var sseClient: SseClient?
    private let clientLock = NSLock()
    private let sseClientFactory: SseClientFactory

    var isConnectionOpened: Bool {
        return sseClient?.isConnectionOpened ?? false
    }

    init(sseClientFactory: SseClientFactory) {
        self.sseClientFactory = sseClientFactory
    }

    func connect(jwt: JwtToken, channels: [String], completion: @escaping SseClient.CompletionHandler) {
        let sseClient = sseClientFactory.create()
        sseClient.connect(token: jwt.rawToken, channels: jwt.channels, completion: completion)
        setCurrentSseClient(sseClient)
    }

    func disconnect() {
        Logger.d("Streaming Connection Handler - Disconnecting SSE client")

        let disconnectingClient = sseClient
        setCurrentSseClient(nil)
        DispatchQueue.global().async {
            disconnectingClient?.disconnect()
        }
    }

    private func setCurrentSseClient(_ newClient: SseClient?) {
        clientLock.lock()
        sseClient = newClient
        clientLock.unlock()
    }
}
