//
//  NotificationParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseNotificationParser {

    func parseIncoming(jsonString: String) -> IncomingNotification?

    func parseSplitUpdate(jsonString: String) throws -> SplitsUpdateNotification

    func parseSplitKill(jsonString: String) throws -> SplitKillNotification

    func parseMySegmentUpdate(jsonString: String) throws -> MySegmentsUpdateNotification

    func parseOccupancy(jsonString: String, timestamp: Int, channel: String) throws -> OccupancyNotification

    func parseControl(jsonString: String) throws -> ControlNotification

    func parseSseError(jsonString: String) throws -> StreamingError

}

class DefaultSseNotificationParser: SseNotificationParser {

    private static let kErrorNotificationName = "error"

    func parseIncoming(jsonString: String) -> IncomingNotification? {
        do {
            let rawNotification = try Json.encodeFrom(json: jsonString, to: RawNotification.self)
            if isError(notification: rawNotification) {
                return IncomingNotification(type: .sseError)
            }
            var type = NotificationType.occupancy
            if let notificationType = try? Json.encodeFrom(json: rawNotification.data,
                                                           to: NotificationTypeValue.self) {
                type = notificationType.type
            }
            return IncomingNotification(type: type, jsonData: rawNotification.data)
        } catch {
            Logger.e("Unexpected error while parsing streaming notification \(error.localizedDescription)")
        }
        return nil
    }

    func parseSplitUpdate(jsonString: String) throws -> SplitsUpdateNotification {
        return try Json.encodeFrom(json: jsonString, to: SplitsUpdateNotification.self)
    }

    func parseSplitKill(jsonString: String) throws -> SplitKillNotification {
        return try Json.encodeFrom(json: jsonString, to: SplitKillNotification.self)
    }

    func parseMySegmentUpdate(jsonString: String) throws -> MySegmentsUpdateNotification {
        return try Json.encodeFrom(json: jsonString, to: MySegmentsUpdateNotification.self)
    }

    func parseOccupancy(jsonString: String, timestamp: Int, channel: String) throws -> OccupancyNotification {
        var notification = try Json.encodeFrom(json: jsonString, to: OccupancyNotification.self)
        notification.channel = channel
        notification.timestamp = timestamp
        return notification
    }

    func parseControl(jsonString: String) throws -> ControlNotification {
        return try Json.encodeFrom(json: jsonString, to: ControlNotification.self)
    }

    func parseSseError(jsonString: String) throws -> StreamingError {
        return try Json.encodeFrom(json: jsonString, to: StreamingError.self)
    }

    func isError(notification: RawNotification) -> Bool {
        return Self.kErrorNotificationName == notification.name
    }
}
