//
//  SseClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct SseClientConstants {
    static let pushNotificationChannelsParam = "channels"
    static let pushNotificationTokenParam = "accessToken"
    static let pushNotificationVersionParam = "v"
    static let pushNotificationVersionValue = "1.1"
}

protocol SseClient: AnyObject {
    typealias CompletionHandler = (Bool) -> Void
    func connect(token: String, channels: [String], completion: @escaping CompletionHandler)
    func disconnect()
    var isConnectionOpened: Bool { get }
}

class DefaultSseClient: SseClient {

    ///
    /// NOTE:
    /// Keep alive is managed through timeoutRequestInverval from URLSession
    /// when session timeouts a retryable error is pushed to event broadcaster

    private let httpClient: HttpClient
    private var endpoint: Endpoint
    private var queue: DispatchQueue
    private var streamRequest: HttpStreamRequest?
    private let streamParser = EventStreamParser()
    private let sseHandler: SseHandler
    private var isDisconnectCalled: Atomic<Bool> = Atomic(false)
    private var isConnected: Atomic<Bool> = Atomic(false)
    private var isFirstMessage: Atomic<Bool> = Atomic(false)
    var isConnectionOpened: Bool {
        return isConnected.value
    }

    init(endpoint: Endpoint, httpClient: HttpClient, sseHandler: SseHandler) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.sseHandler = sseHandler
        self.queue = DispatchQueue(label: "Split SSE Client")
    }

    func connect(token: String, channels: [String], completion: @escaping CompletionHandler) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let parameters: [String: Any] = [
                SseClientConstants.pushNotificationTokenParam: token,
                SseClientConstants.pushNotificationChannelsParam: self.createChannelsQueryString(channels: channels),
                SseClientConstants.pushNotificationVersionParam: SseClientConstants.pushNotificationVersionValue
            ]
            do {
                self.streamRequest = try self.httpClient.sendStreamRequest(endpoint: self.endpoint,
                                                          parameters: parameters, headers: self.endpoint.headers)
                .getResponse(responseHandler: self.responseHandler(completion: completion),
                             incomingDataHandler: self.incommingDataHandler(completion: completion),
                             closeHandler: self.closeHandler(),
                             errorHandler: self.errorHandler())
            } catch {
                Logger.e("Error while connecting to streaming: \(error.localizedDescription)")
                self.handleError(retryable: false)
            }
        }
    }

    func isConnectionConfirmed(message: [String: String]) -> Bool {
        return streamParser.isKeepAlive(values: message) || sseHandler.isConnectionConfirmed(message: message)
    }

    func triggerMessageHandler(message: [String: String]) {
        sseHandler.handleIncomingMessage(message: message)
    }

    func handleError(retryable: Bool) {
        self.isConnected.set(false)
        sseHandler.reportError(isRetryable: retryable)
    }

    func handleConnectionClosed() {
        self.isConnected.set(false)
        sseHandler.reportError(isRetryable: true)
    }

    func handleError(_ error: HttpError) {
        self.isConnected.set(false)
        sseHandler.reportError(isRetryable: !isClientRelatedError(error))
    }

    private func isClientRelatedError(_ error: HttpError) -> Bool {
        switch error {
        case .clientRelated:
            return true
        default:
            return false
        }
    }

    func disconnect() {
        Logger.d("Disconnecting SSE client")
        isDisconnectCalled.set(true)
        isConnected.set(false)
        streamRequest?.close()
    }

    // MARK: Handlers for Stream request
    func responseHandler(completion: @escaping CompletionHandler) -> HttpStreamRequest.ResponseHandler {
        return { [weak self] response in
            guard let self = self else { return }
            if response.code != 200 {
                completion(false)
                self.handleError(retryable: !response.isClientError)
                return
            }
            Logger.d("Streaming connected")

        }
    }

    func incommingDataHandler(completion: @escaping CompletionHandler) -> HttpStreamRequest.IncomingDataHandler {
        isFirstMessage.set(true)
        return { [weak self] data in

            guard let self = self else { return }

            let values = self.streamParser.parse(streamChunk: data.stringRepresentation)

            if self.isFirstMessage.value {
                if self.isConnectionConfirmed(message: values) {
                    self.isFirstMessage.set(false)
                    completion(true)
                    self.isConnected.set(true)
                } else {
                    completion(false)
                    self.isConnected.set(false)
                    self.sseHandler.reportError(isRetryable: true)
                }
            }
            if !self.streamParser.isKeepAlive(values: values) {
                Logger.d("Push message received: \(values)")
                self.triggerMessageHandler(message: values)
            }
        }
    }

    func closeHandler() -> HttpStreamRequest.CloseHandler {
        return { [weak self] in
            guard let self = self else { return }
            Logger.d("Streaming connection closed")
            if !self.isDisconnectCalled.value {
                self.handleConnectionClosed()
            }
        }
    }

    func errorHandler() -> HttpStreamRequest.ErrorHandler {
        return { [weak self] error in
            guard let self = self else { return }
            Logger.d("Streaming disconnected: \(error.localizedDescription)")
            self.handleError(error)
        }
    }
}

// MARK: Private
extension DefaultSseClient {
    private func createChannelsQueryString(channels: [String]) -> String {
        return channels.joined(separator: ",")
    }
}
