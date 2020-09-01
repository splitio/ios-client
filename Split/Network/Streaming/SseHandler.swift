//
//  SseHandler.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseHandler {
    func handleIncommingMessage(message: [String: String])
}

class DefaultSseHandler: SseHandler {
    private let kDataField = "data"
    let notificationProcessor: SseNotificationProcessor
    let notificationParser: SseNotificationParser
    let notificationManagerKeeper: NotificationManagerKeeper

    init(notificationProcessor: SseNotificationProcessor,
         notificationParser: SseNotificationParser,
         notificationManagerKeeper: NotificationManagerKeeper) {

        self.notificationProcessor = notificationProcessor
        self.notificationParser = notificationParser
        self.notificationManagerKeeper = notificationManagerKeeper
    }

    func handleIncommingMessage(message: [String: String]) {
        guard let data = message[kDataField] else {
            return
        }

        guard let incomingNotification = notificationParser.parseIncoming(jsonString: data) else {
            return
        }

        switch incomingNotification.type {
        case .control:
            print("TODO: handle control here")
        case .error:
            print("TODO: handle error here")
        case .occupancy:
            handleOccupancy(incomingNotification)
        case .mySegmentsUpdate, .splitKill, .splitUpdate:
            notificationProcessor.process(incomingNotification)
        default:
            Logger.w("SSE Handler: Unknown notification")
        }
    }

    private func handleOccupancy(_ notification: IncomingNotification) {
        if let jsonData = notification.jsonData {
            do {
                let notification = try notificationParser.parseOccupancy(jsonString: jsonData)
                notificationManagerKeeper.handleIncomingPresenceEvent(notificiation: notification)
            } catch {
                Logger.w("Error while handling occupancy notification")
            }
        }
    }
}
