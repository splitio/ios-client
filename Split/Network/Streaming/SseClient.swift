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

    typealias EventHandler = () -> Void
    typealias MessageHandler = ([String: String]) -> Void
    typealias ErrorHandler = (Bool) -> Void

    var onKeepAliveHandler: EventHandler? { get set }
    var onErrorHandler: ErrorHandler? { get set }
    var onDisconnectHandler: EventHandler? { get set }
    var onMessageHandler: MessageHandler? { get set }

    func connect(token: String, channels: [String]) -> SseConnectionResult
    func disconnect()
}

class DefaultSseClient: SseClient {
    private let httpClient: HttpClient
    private var endpoint: Endpoint
    private var queue: DispatchQueue
    private var streamRequest: HttpStreamRequest?
    private let streamParser = EventStreamParser()

    var onKeepAliveHandler: SseClient.EventHandler?
    var onErrorHandler: SseClient.ErrorHandler?
    var onDisconnectHandler: SseClient.EventHandler?
    var onMessageHandler: SseClient.MessageHandler?

    init(endpoint: Endpoint, httpClient: HttpClient) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.queue = DispatchQueue(label: "Split SSE Client")
    }

    func connect(token: String, channels: [String]) -> SseConnectionResult {

        let responseSemaphore = DispatchSemaphore(value: 0)
        var connectionResult: SseConnectionResult?

        queue.async {
            let values = SyncDictionarySingleWrapper<String, String>()
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

                    if self.streamParser.parseLineAndAppendValue(streamLine: data.stringRepresentation,
                                                                 messageValues: values) {
                        if self.streamParser.isKeepAlive(values: values.all) {
                            values.removeAll()
                            self.triggerKeepAliveHandler()
                        } else {
                            self.triggerMessageHandler(message: values.takeAll())
                        }
                    }
                }, closeHandler: {
                    self.triggerCloseHandler()

                }, errorHandler: { error in
                    Logger.e("Error in stream request: \(error.message)")
                    self.triggerOnError(isRecoverable: true)
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
        if let onMessage = self.onMessageHandler {
            onMessage(message)
        }
    }

    func triggerCloseHandler() {
        if let onDisconnect = self.onDisconnectHandler {
            onDisconnect()
        }
    }

    func triggerKeepAliveHandler() {
        if let onKeepAlive = self.onKeepAliveHandler {
            onKeepAlive()
        }
    }

    func triggerOnError(isRecoverable: Bool) {
        if let onError = self.onErrorHandler {
            onError(isRecoverable)
        }
    }

    func disconnect() {
        // TODO: Implement this method and close method in StreamRequest!!
    }
}

// MARK: Private
extension DefaultSseClient {
    private func createChannelsQueryString(channels: [String]) -> String {
        return channels.joined(separator: ",")
    }
}
