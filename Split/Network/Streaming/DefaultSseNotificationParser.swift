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

    func parseTargetingRuleNotification(jsonString: String, type: NotificationType) throws
        -> TargetingRuleUpdateNotification

    func parseSplitKill(jsonString: String) throws -> SplitKillNotification

    func parseMembershipsUpdate(jsonString: String, type: NotificationType) throws -> MembershipsUpdateNotification

    func parseOccupancy(jsonString: String, timestamp: Int64, channel: String) throws -> OccupancyNotification

    func parseControl(jsonString: String) throws -> ControlNotification

    func parseSseError(jsonString: String) throws -> StreamingError

    func isError(event: [String: String]) -> Bool

    func extractUserKeyHashFromChannel(channel: String) -> String?
}

class DefaultSseNotificationParser: SseNotificationParser {
    private static let kErrorNotificationName = "error"

    func parseIncoming(jsonString: String) -> IncomingNotification? {
        do {
            let rawNotification = try Json.decodeFrom(json: jsonString, to: RawNotification.self)
            if isError(notification: rawNotification) {
                return IncomingNotification(type: .sseError)
            }
            var type = NotificationType.occupancy
            if let notificationType = try? Json.decodeFrom(
                json: rawNotification.data,
                to: NotificationTypeValue.self) {
                type = notificationType.type
            }
            return IncomingNotification(
                type: type,
                channel: rawNotification.channel,
                jsonData: rawNotification.data,
                timestamp: rawNotification.timestamp ?? 0)
        } catch {
            Logger.e("Unexpected error while parsing streaming notification \(error.localizedDescription)")
        }
        return nil
    }

    func parseTargetingRuleNotification(
        jsonString: String,
        type: NotificationType) throws -> TargetingRuleUpdateNotification {
        var notification = try Json.decodeFrom(json: jsonString, to: TargetingRuleUpdateNotification.self)
        notification.entityType = type
        return notification
    }

    func parseSplitKill(jsonString: String) throws -> SplitKillNotification {
        return try Json.decodeFrom(json: jsonString, to: SplitKillNotification.self)
    }

    func parseMembershipsUpdate(jsonString: String, type: NotificationType) throws -> MembershipsUpdateNotification {
        var notification = try Json.decodeFrom(json: jsonString, to: MembershipsUpdateNotification.self)
        notification.segmentType = type
        return notification
    }

    func parseOccupancy(jsonString: String, timestamp: Int64, channel: String) throws -> OccupancyNotification {
        var notification = try Json.decodeFrom(json: jsonString, to: OccupancyNotification.self)
        notification.channel = channel
        notification.timestamp = timestamp
        return notification
    }

    func parseControl(jsonString: String) throws -> ControlNotification {
        return try Json.decodeFrom(json: jsonString, to: ControlNotification.self)
    }

    func parseSseError(jsonString: String) throws -> StreamingError {
        return try Json.decodeFrom(json: jsonString, to: StreamingError.self)
    }

    func isError(notification: RawNotification) -> Bool {
        return Self.kErrorNotificationName == notification.name?.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isError(event: [String: String]) -> Bool {
        return event[EventStreamParser.kEventField]?
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            == Self.kErrorNotificationName
    }

    func extractUserKeyHashFromChannel(channel: String) -> String? {
        let segmentsInChannel = channel.split(separator: "_")
        if segmentsInChannel.count > 2 {
            return String(segmentsInChannel[2])
        }
        return nil
    }
}
