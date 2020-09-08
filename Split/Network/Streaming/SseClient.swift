//
//  SseClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct SseClientConstants {
    static let contentTypeHeaderStream = "Content-Type"
    static let contentTypeHeaderValueStream = "text/event-stream"
    static let pushNotificationChannelsParam = "channels"
    static let pushNotificationTokenParam = "accessToken"
    static let pushNotificationVersionParam = "v"
    static let pushNotificationVersionValue = "1.1"
}

struct SseConnectionResult {
    let success: Bool
    let errorIsRecoverable: Bool
}

protocol SseClient {
    func connect(token: String, channels: [String]) -> SseConnectionResult
    func disconnect()
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

    init(endpoint: Endpoint, httpClient: HttpClient, sseHandler: SseHandler) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.sseHandler = sseHandler
        self.queue = DispatchQueue(label: "Split SSE Client")
    }

    func connect(token: String, channels: [String]) -> SseConnectionResult {

        let responseSemaphore = DispatchSemaphore(value: 0)
        var connectionResult: SseConnectionResult?

        queue.async {
            let parameters: [String: Any] = [
                SseClientConstants.pushNotificationTokenParam: token,
                SseClientConstants.pushNotificationChannelsParam: self.createChannelsQueryString(channels: channels),
                SseClientConstants.pushNotificationVersionParam: SseClientConstants.pushNotificationVersionValue
            ]
            let headers = [SseClientConstants.contentTypeHeaderStream: SseClientConstants.contentTypeHeaderValueStream]
            do {
                self.streamRequest = try self.httpClient.sendStreamRequest(endpoint: self.endpoint,
                                                                           parameters: parameters,
                                                                           headers: headers)
                .getResponse(responseHandler: { response in

                    connectionResult = SseConnectionResult(success: response.code == 200,
                                                           errorIsRecoverable: !response.isCredentialsError)
                    responseSemaphore.signal()

                }, incomingDataHandler: { data in

                    let values = self.streamParser.parse(streamChunk: data.stringRepresentation)
                    if !self.streamParser.isKeepAlive(values: values) {
                        self.triggerMessageHandler(message: values)
                    }

                }, closeHandler: {
                    self.handleConnectionClosed()

                }, errorHandler: { error in
                    Logger.e("Error in stream request: \(error.message)")
                    self.handleError(error)
                })
            } catch {
                Logger.e("Error while connecting to streaming: \(error.localizedDescription)")
                responseSemaphore.signal()
                connectionResult = SseConnectionResult(success: false, errorIsRecoverable: false)
            }
        }
        responseSemaphore.wait()
        return connectionResult ?? SseConnectionResult(success: false, errorIsRecoverable: false)
    }

    func triggerMessageHandler(message: [String: String]) {
        sseHandler.handleIncomingMessage(message: message)
    }

    func handleConnectionClosed() {
        sseHandler.reportError(isRetryable: true)
    }

    func handleError(_ error: HttpError) {
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
        streamRequest?.close()
    }
}

// MARK: Private
extension DefaultSseClient {
    private func createChannelsQueryString(channels: [String]) -> String {
        return channels.joined(separator: ",")
    }
}
