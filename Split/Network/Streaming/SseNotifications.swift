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
    let channel: String?
    let timestamp: Int64?
    let data: String
}

/// Notification types of any type
enum NotificationType: Decodable {
    case splitUpdate
    case mySegmentsUpdate
    case mySegmentsUpdateV2
    case splitKill
    case occupancy
    case sseError
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
        case "my_segments_update_v2":
            return NotificationType.mySegmentsUpdateV2
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
    let timestamp: Int64

    init(type: NotificationType, channel: String? = nil, jsonData: String? = nil, timestamp: Int64 = 0) {
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
        case streamingResumed
        case streamingDisabled
        case streamingPaused
        case streamingReset
        case unknown

        init(from decoder: Decoder) throws {
            let stringValue = try? decoder.singleValueContainer().decode(String.self)
            self = ControlType.enumFromString(string: stringValue ?? "unknown")
        }

        static func enumFromString(string: String) -> ControlType {
            switch string.lowercased() {
            case "streaming_resumed":
                return ControlType.streamingResumed
            case "streaming_disabled":
                return ControlType.streamingDisabled
            case "streaming_paused":
                return ControlType.streamingPaused
            case "streaming_reset":
                return ControlType.streamingReset
            default:
                return ControlType.unknown
            }
        }
    }
    let controlType: ControlType
}
/// MySegmentsUpdateNotificationJson: Indicates change in MySegments parsed from de incoming JSON
/// For my segments update notification, two notifications are used
/// to avoid adding an read-write variable for channel
struct MySegmentsUpdateNotificationJson: NotificationTypeField {
    var type: NotificationType {
        return .mySegmentsUpdate
    }
    let changeNumber: Int64
    let includesPayload: Bool
    let segmentList: [String]?
}

/// MySegmentsUpdateNotification: Indicates change in MySegments. This struct has also the userKey (readonly)
struct MySegmentsUpdateNotification: NotificationTypeField {
    var type: NotificationType {
        return .mySegmentsUpdate
    }
    let changeNumber: Int64
    let includesPayload: Bool
    let segmentList: [String]?
    let userKeyHash: String

    init(json: MySegmentsUpdateNotificationJson, userKeyHash: String) {
        self.changeNumber = json.changeNumber
        self.includesPayload = json.includesPayload
        self.segmentList = json.segmentList
        self.userKeyHash = userKeyHash
    }

    init(changeNumber: Int64,
         includesPayload: Bool,
         segmentList: [String]?,
         userKeyHash: String) {
        self.changeNumber = changeNumber
        self.includesPayload = includesPayload
        self.segmentList = segmentList
        self.userKeyHash = userKeyHash
    }
}

enum MySegmentUpdateStrategy: Decodable {
    case unboundedFetchRequest
    case boundedFetchRequest
    case keyList
    case segmentRemoval
    case unknown

    init(from decoder: Decoder) throws {
        let intValue = try? decoder.singleValueContainer().decode(Int.self)
        self = MySegmentUpdateStrategy.enumFromInt(intValue ?? 0)
    }

    static func enumFromInt(_ intValue: Int) -> MySegmentUpdateStrategy {
        switch intValue {
        case 0:
            return MySegmentUpdateStrategy.unboundedFetchRequest
        case 1:
            return MySegmentUpdateStrategy.boundedFetchRequest
        case 2:
            return MySegmentUpdateStrategy.keyList
        case 3:
            return MySegmentUpdateStrategy.segmentRemoval
        default:
            return MySegmentUpdateStrategy.unknown
        }
    }
}

struct KeyList: Decodable {
    let added: Set<UInt64>
    let removed: Set<UInt64>

    enum CodingKeys: String, CodingKey {
        case added = "a"
        case removed = "r"
    }
}

/// Indicates change in MySegments (Optimized version)
struct MySegmentsUpdateV2Notification: NotificationTypeField {
    var type: NotificationType {
        return .mySegmentsUpdateV2
    }
    let changeNumber: Int64?
    let compressionType: CompressionType
    let updateStrategy: MySegmentUpdateStrategy
    let segmentName: String?
    let data: String?

    enum CodingKeys: String, CodingKey {
        case changeNumber
        case segmentName
        case compressionType = "c"
        case updateStrategy = "u"
        case data = "d"
    }
}

/// Indicates that a Split was killed
struct SplitKillNotification: NotificationTypeField {
    var type: NotificationType {
        return .splitKill
    }
    let changeNumber: Int64
    let splitName: String
    let defaultTreatment: String
}

/// indicates Split changes
struct SplitsUpdateNotification: NotificationTypeField {
    var type: NotificationType {
        return .splitUpdate
    }
    let changeNumber: Int64
}

/// Indicates a notification related to occupancy
struct OccupancyNotification: NotificationTypeField {
    private let kControlPriToken = "control_pri"
    private let kControlSecToken = "control_sec"
    var channel: String?
    var timestamp: Int64 = 0

    var type: NotificationType {
        return .occupancy
    }
    struct Metrics: Decodable {
        let publishers: Int
    }
    let metrics: Metrics

    enum CodingKeys: String, CodingKey {
        case metrics
    }

    var isControlPriChannel: Bool {
        return channel?.contains(kControlPriToken) ?? false
    }

    var isControlSecChannel: Bool {
        return channel?.contains(kControlSecToken) ?? false
    }
}

/// Indicates a streaming error related
struct StreamingError: NotificationTypeField {
    var type: NotificationType {
        return .sseError
    }

    let message: String
    let code: Int
    let statusCode: Int

    var isRetryable: Bool {
        return  code >= 40140 &&  code <= 40149
    }

    var shouldIgnore: Bool {
        return  !(code >= 40000 && code <= 49999)
    }
}
