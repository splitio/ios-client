//
//  SseNotifications.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Base json data received
/// "name" field when present indicates
/// whether the notification is error or control
/// "data" field contains IncomingNotification
struct RawNotification: Decodable {
    let name: String?
    let data: String
}

/// Notification types of any type
enum NotificationType: Decodable {
    case splitUpdate
    case mySegmentsUpdate
    case splitKill
    case occupancy
    case error
    case control
    case unknown

    init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = NotificationType.enumFromString(string: stringValue ?? "unknown")
    }

    static func enumFromString(string: String) -> NotificationType {
        switch string.lowercased() {
        case "split_update":
            return NotificationType.splitUpdate
        case "my_segments_update":
            return NotificationType.mySegmentsUpdate
        case "split_kill":
            return NotificationType.splitKill
        case "control":
            return NotificationType.control
        default:
            return NotificationType.unknown
        }
    }
}

/// Types of notifications handled by split events
/// Used to inherit from
protocol NotificationTypeField: Decodable {
    var type: NotificationType { get }
}

struct NotificationTypeValue: NotificationTypeField {
    var type: NotificationType
}

// Base notification data used by split events
// Json data has real notification data, type is used to parse data
// to correct DTO
struct IncomingNotification {
    let type: NotificationType
    let channel: String?
    let jsonData: String?
    let timestamp: Int

    init(type: NotificationType, channel: String? = nil, jsonData: String? = nil, timestamp: Int = 0) {
        self.type = type
        self.channel = channel
        self.jsonData = jsonData
        self.timestamp = timestamp
    }
}

/// Used to control streaming status
struct ControlNotification: NotificationTypeField {
    private (set) var type: NotificationType

    enum ControlType: Decodable {
        case streamingEnabled
        case streamingDisabled
        case streamingPaused
        case unknown

        init(from decoder: Decoder) throws {
            let stringValue = try? decoder.singleValueContainer().decode(String.self)
            self = ControlType.enumFromString(string: stringValue ?? "unknown")
        }

        static func enumFromString(string: String) -> ControlType {
            switch string.lowercased() {
            case "streaming_enabled":
                return ControlType.streamingEnabled
            case "streaming_disabled":
                return ControlType.streamingDisabled
            case "streaming_paused":
                return ControlType.streamingPaused
            default:
                return ControlType.unknown
            }
        }
    }
    let controlType: ControlType
}

/// Indicates change in MySegments
struct MySegmentsUpdateNotification: NotificationTypeField {
    private (set) var type: NotificationType
    let changeNumber: Int
    let includesPayload: Bool
    let segmentList: [String]?
}

/// Indicates that a Split was killed
struct SplitKillNotification: NotificationTypeField {
    private (set) var type: NotificationType
    let changeNumber: Int
    let splitName: String
    let defaultTreatment: String
}

/// indicates Split changes
struct SplitsUpdateNotification: NotificationTypeField {
    private (set) var type: NotificationType
    let changeNumber: Int
}

/// Indicates a notification related to occupancy
struct OccupancyNotification: NotificationTypeField {
    private (set) var type: NotificationType = .occupancy
    struct Metrics: Decodable {
        let publishers: Int
    }
    let metrics: Metrics

    enum CodingKeys: String, CodingKey {
        case metrics
    }
}

/// Indicates a streaming error related
struct StreamingError {
    let message: String
    let code: Int
    let statusCode: Int
}
