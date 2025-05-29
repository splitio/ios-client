//
//  SseConnectionHandler.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Oct-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SseConnectionHandler {
    private let clientLock = NSLock()
    private let sseClientFactory: SseClientFactory
    private var curClientId: String?
    private let clients = SynchronizedDictionary<String, SseClient>()

    var isConnectionOpened: Bool {
        guard let id = curClientId else { return false }
        return clients.value(forKey: id)?.isConnectionOpened ?? false
    }

    init(sseClientFactory: SseClientFactory) {
        self.sseClientFactory = sseClientFactory
    }

    func connect(jwt: JwtToken, channels: [String], completion: @escaping SseClient.CompletionHandler) {
        let sseClient = sseClientFactory.create()
        addSseClient(sseClient)
        sseClient.connect(token: jwt.rawToken, channels: jwt.channels, completion: completion)
    }

    func disconnect() {
        Logger.d("Streaming Connection Handler - Disconnecting SSE client")
        let disconnectingClientId = curClientId
        clearClientId()
        DispatchQueue.general.async { [weak self] in
            guard let self = self else { return }
            guard let clientId = disconnectingClientId else { return }
            let cli = self.getSseClient(id: clientId)
            cli?.disconnect()
            self.removeSseClient(id: clientId)
        }
    }

    func destroy() {
        for client in clients.takeAll().values {
            client.disconnect()
        }
    }

    private func clearClientId() {
        clientLock.lock()
        curClientId = nil
        clientLock.unlock()
    }

    private func newClientId() -> String {
        let id = UUID().uuidString
        clientLock.lock()
        curClientId = id
        clientLock.unlock()
        return id
    }

    private func addSseClient(_ newClient: SseClient) {
        let id = newClientId()
        clients.setValue(newClient, forKey: id)
    }

    private func getSseClient(id: String) -> SseClient? {
        return clients.value(forKey: id)
    }

    private func removeSseClient(id: String) {
        clients.removeValue(forKey: id)
    }
}
