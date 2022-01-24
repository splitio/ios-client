//
//  SseHandler.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseHandler {
    func isConnectionConfirmed(message: [String: String]) -> Bool
    func handleIncomingMessage(message: [String: String])
    func reportError(isRetryable: Bool)
}

class DefaultSseHandler: SseHandler {
    let notificationProcessor: SseNotificationProcessor
    let notificationParser: SseNotificationParser
    let notificationManagerKeeper: NotificationManagerKeeper
    let broadcasterChannel: PushManagerEventBroadcaster
    let telemetryProducer: TelemetryRuntimeProducer?

    private var lastControlTimestamp: Int64 = 0

    init(notificationProcessor: SseNotificationProcessor,
         notificationParser: SseNotificationParser,
         notificationManagerKeeper: NotificationManagerKeeper,
         broadcasterChannel: PushManagerEventBroadcaster,
         telemetryProducer: TelemetryRuntimeProducer?) {

        self.notificationProcessor = notificationProcessor
        self.notificationParser = notificationParser
        self.notificationManagerKeeper = notificationManagerKeeper
        self.broadcasterChannel = broadcasterChannel
        self.telemetryProducer = telemetryProducer
    }

    func isConnectionConfirmed(message: [String: String]) -> Bool {
        if message[EventStreamParser.kIdField] != nil && message[EventStreamParser.kDataField] == nil &&
                message[EventStreamParser.kEventField] == nil {
            return true
        }
        return message[EventStreamParser.kDataField] != nil && !notificationParser.isError(event: message)
    }

    func handleIncomingMessage(message: [String: String]) {
        guard let data = message[EventStreamParser.kDataField] else {
            return
        }

        if notificationParser.isError(event: message) {
            handleSseError(data)
            return
        }

        guard let incomingNotification = notificationParser.parseIncoming(jsonString: data) else {
            return
        }
        Logger.d("IncomingNotification: \(incomingNotification.type)")
        switch incomingNotification.type {
        case .control:
            handleControl(incomingNotification)
        case .occupancy:
            handleOccupancy(incomingNotification)
        case .mySegmentsUpdate, .splitKill, .splitUpdate, .mySegmentsUpdateV2:
            if notificationManagerKeeper.isStreamingActive {
                notificationProcessor.process(incomingNotification)
            }
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
                                                                         timestamp: notification.timestamp,
                                                                         channel: notification.channel ?? "")
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

    private func handleSseError(_ json: String) {
        do {
            let error = try notificationParser.parseSseError(jsonString: json)
            telemetryProducer?.recordStreamingEvent(type: .ablyError, data: Int64(error.code))
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
