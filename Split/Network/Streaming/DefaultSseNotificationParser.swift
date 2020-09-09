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

    func parseOccupancy(jsonString: String) throws -> OccupancyNotification

    func parseControl(jsonString: String) throws -> ControlNotification

}

class DefaultSseNotificationParser: SseNotificationParser {

    private static let kErrorNotificationName = "error"

    func parseIncoming(jsonString: String) -> IncomingNotification? {
        do {
            let rawNotification = try Json.encodeFrom(json: jsonString, to: RawNotification.self)
            if isError(notification: rawNotification) {
                return IncomingNotification(type: .error)
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

    func parseOccupancy(jsonString: String) throws -> OccupancyNotification {
        return try Json.encodeFrom(json: jsonString, to: OccupancyNotification.self)
    }

    func parseControl(jsonString: String) throws -> ControlNotification {
        return try Json.encodeFrom(json: jsonString, to: ControlNotification.self)
    }

    func isError(notification: RawNotification) -> Bool {
        return Self.kErrorNotificationName == notification.name
    }
}
