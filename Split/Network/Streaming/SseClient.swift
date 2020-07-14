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
    static let pushNotificationChannelsParam = "channel"
    static let pushNotificationTokenParam = "accessToken"
    static let pushNotificationVersionParam = "v"
    static let pushNotificationVersionValue = "1.1"
}

class SseClient {
    private let httpClient: HttpClient
    private var endpoint: Endpoint
    private var queue: DispatchQueue
    private var streamRequest: HttpStreamRequest?


    typealias EventHandler = () -> Void
    typealias MessageHandler = (Data) -> Void
    typealias ErrorHandler = (Bool) -> Void

    var onOpenHandler: EventHandler?
    var onErrorHandler: ErrorHandler?
    var onDisconnectHandler: EventHandler?
    var onMessageHandler: MessageHandler?

    init(endpoint: Endpoint, httpClient: HttpClient) {
        self.endpoint = endpoint
        self.httpClient = httpClient
        self.queue = DispatchQueue(label: "Split SSE Client")
    }

    func connect(token: String, channels: [String]) {
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
                        self.handleResponse(response)
                    }, incomingDataHandler: { data in
                        if let onMessage = self.onMessageHandler {
                            onMessage(data)
                        }
                    }, closeHandler: {
                        if let onDisconnect = self.onDisconnectHandler {
                            onDisconnect()
                        }
                    }, errorHandler: { error in
                        Logger.e("Error in stream request: \(error.message)")
                        self.triggerOnError(isRecoverable: true)
                    })
            } catch {
                Logger.e("Error while connection to streaming: \(error.localizedDescription)")
                self.triggerOnError(isRecoverable: false)
            }
        }
    }

    func handleResponse(_ response: HttpResponse) {
        if response.result.isSuccess {
            if let onOpen = self.onOpenHandler {
                onOpen()
            }
        } else {
            self.triggerOnError(isRecoverable: !response.isCredentialsError)
        }
    }

    func triggerOnError(isRecoverable: Bool) {
        if let onError = self.onErrorHandler {
            onError(isRecoverable)
        }
    }
}

// MARK: Private
extension SseClient {
    private func createChannelsQueryString(channels: [String]) -> String {
        // TODO: Implement this method
        return "dummychannel"
    }
}
