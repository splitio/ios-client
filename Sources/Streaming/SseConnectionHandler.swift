//
//  SseConnectionHandler.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Oct-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import Logging

public class SseConnectionHandler: @unchecked Sendable {
    private let clientLock = NSLock()
    private let sseClientFactory: SseClientFactory
    private var curClientId: String?
    private var clients = [String: SseClient]()

    var isConnectionOpened: Bool {
        clientLock.lock()
        defer { clientLock.unlock() }
        guard let id = curClientId else { return false }
        return clients[id]?.isConnectionOpened ?? false
    }

    public init(sseClientFactory: SseClientFactory) {
        self.sseClientFactory = sseClientFactory
    }

    public func connect(token: String, channels: [String], completion: @escaping SseClient.CompletionHandler) {
        let sseClient = sseClientFactory.create()
        addSseClient(sseClient)
        sseClient.connect(token: token, channels: channels, completion: completion)
    }

    public func disconnect() {
        Logger.d("Streaming Connection Handler - Disconnecting SSE client")
        let disconnectingClientId = curClientId
        clearClientId()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            guard let clientId = disconnectingClientId else { return }
            let cli = self.getSseClient(id: clientId)
            cli?.disconnect()
            self.removeSseClient(id: clientId)
        }
    }

    public func destroy() {
        let all: [SseClient]
        clientLock.lock()
        all = Array(clients.values)
        clients.removeAll()
        clientLock.unlock()
        for client in all {
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
        clientLock.lock()
        clients[id] = newClient
        clientLock.unlock()
    }

    private func getSseClient(id: String) -> SseClient? {
        clientLock.lock()
        defer { clientLock.unlock() }
        return clients[id]
    }

    private func removeSseClient(id: String) {
        clientLock.lock()
        clients.removeValue(forKey: id)
        clientLock.unlock()
    }
}
