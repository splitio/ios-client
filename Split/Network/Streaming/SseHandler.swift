//
//  SseHandler.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseHandler {
    func handleIncomingMessage(message: [String: String])
    func reportError(isRetryable: Bool)
}

class DefaultSseHandler: SseHandler {
    private let kDataField = "data"
    let notificationProcessor: SseNotificationProcessor
    let notificationParser: SseNotificationParser
    let notificationManagerKeeper: NotificationManagerKeeper
    let broadcasterChannel: PushManagerEventBroadcaster

    private var lastControlTimestamp = 0

    init(notificationProcessor: SseNotificationProcessor,
         notificationParser: SseNotificationParser,
         notificationManagerKeeper: NotificationManagerKeeper,
         broadcasterChannel: PushManagerEventBroadcaster) {

        self.notificationProcessor = notificationProcessor
        self.notificationParser = notificationParser
        self.notificationManagerKeeper = notificationManagerKeeper
        self.broadcasterChannel = broadcasterChannel
    }

    func handleIncomingMessage(message: [String: String]) {
        guard let data = message[kDataField] else {
            return
        }

        guard let incomingNotification = notificationParser.parseIncoming(jsonString: data) else {
            return
        }

        switch incomingNotification.type {
        case .control:
            handleControl(incomingNotification)
        case .occupancy:
            handleOccupancy(incomingNotification)
        case .mySegmentsUpdate, .splitKill, .splitUpdate:
            notificationProcessor.process(incomingNotification)
        case .sseError:
            handleSseError(incomingNotification)
        default:
            Logger.w("SSE Handler: Unknown notification")
        }
    }

    func reportError(isRetryable: Bool) {
        broadcasterChannel.push(event: isRetryable ? .pushRetryableError : .pushNonRetryableError)
    }

    private func handleOccupancy(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                let notification = try notificationParser.parseOccupancy(jsonString: jsonData,
                                                                         timestamp: notification.timestamp)
                notificationManagerKeeper.handleIncomingPresenceEvent(notification: notification)
            } catch {
                Logger.w("Error while handling occupancy notification")
            }
        }
    }

    private func handleControl(_ notification: IncomingNotification) {
        if notification.timestamp <= lastControlTimestamp {
            return
        }
        lastControlTimestamp = notification.timestamp
        if let jsonData = notification.jsonData {
            do {
                let notification = try notificationParser.parseControl(jsonString: jsonData)
                notificationManagerKeeper.handleIncomingControl(notification: notification)
            } catch {
                Logger.w("Error while handling control notification")
            }
        }
    }

    private func handleSseError(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                let error = try notificationParser.parseSseError(jsonString: jsonData)
                Logger.w("Streaming error notification received: \(error.message)")
                if error.shouldIgnore {
                    Logger.w("Error ignored")
                    return
                }
                broadcasterChannel.push(event: error.isRetryable ? .pushRetryableError : .pushNonRetryableError)
            } catch {
                Logger.w("Error while parsing streaming error notification")
            }
        }
    }
}
