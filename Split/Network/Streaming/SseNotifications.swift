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
    case ruleBasedSegmentUpdate
    case mySegmentsUpdate
    case myLargeSegmentsUpdate
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
        case "rb_segment_update":
            return NotificationType.ruleBasedSegmentUpdate
        case "memberships_ms_update":
            return NotificationType.mySegmentsUpdate
        case "memberships_ls_update":
            return NotificationType.myLargeSegmentsUpdate
        case "split_kill":
            return NotificationType.splitKill
        case "control":
            return NotificationType.control
        default:
            return NotificationType.unknown
        }
    }
}

/// Types of notifications handled by events
/// Used to inherit from
protocol NotificationTypeField: Decodable {
    var type: NotificationType { get }
}

struct NotificationTypeValue: NotificationTypeField {
    var type: NotificationType
}

// Base notification data used by events
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
    private(set) var type: NotificationType

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

struct MembershipsUpdateNotification: NotificationTypeField {
    var segmentType: NotificationType?
    var type: NotificationType {
        guard let notificationType = segmentType else {
            return .unknown
        }
        return notificationType
    }

    let changeNumber: Int64?
    let compressionType: CompressionType?
    let updateStrategy: MySegmentUpdateStrategy
    let segments: [String]?
    let data: String?
    let hash: FetchDelayAlgo?
    let seed: Int?
    let timeMillis: Int64?

    enum CodingKeys: String, CodingKey {
        case changeNumber = "cn"
        case segments = "n"
        case compressionType = "c"
        case updateStrategy = "u"
        case data = "d"
        case hash = "h"
        case seed = "s"
        case timeMillis = "i"
    }

    //  uw = unwrappedd value => unwrapped value for optional properties
    /// A computed property that returns a non-null value (nnv) for the `segments` array.
    ///
    /// This property ensures that the `segments` array is always non-optional.
    /// If `segments` is `nil`, it returns an empty array instead of `nil`.
    /// This is useful for safely accessing the array without needing to unwrap the optional value.
    ///
    /// - Returns: A non-optional array of `String`. Returns an empty array if `segments` is `nil`.
    ///
    /// - Example:
    /// ```swift
    /// let example = uwSegments  // If `segments` is nil, it returns [].
    /// ```
    var uwSegments: [String] {
        return segments ?? []
    }

    /// A computed property that returns a non-null value (nnv) for the `timeMillis` value.
    ///
    /// This property ensures that the `timeMillis` array is always non-optional.
    /// If `timeMillis` is `nil`, it returns an empty array instead of `nil`.
    /// This is useful for safely accessing the array without needing to unwrap the optional value.
    ///
    /// - Returns: A non-optional `Int64`. Returns an empty array if `timeMillis` is `nil`.
    ///
    /// - Example:
    /// ```swift
    /// let example = uwTimeMillis  // If `timeMillis` is nil, it returns 0.
    /// ```
    var uwTimeMillis: Int64 {
        return timeMillis ?? 0
    }

    var uwChangeNumber: Int64 {
        return changeNumber ?? -1
    }

    var uwHash: FetchDelayAlgo {
        return hash ?? .murmur332
    }

    var uwSeed: Int {
        return seed ?? 0
    }
}

/// Indicates that a feature flag was killed
struct SplitKillNotification: NotificationTypeField {
    var type: NotificationType {
        return .splitKill
    }

    let changeNumber: Int64
    let splitName: String
    let defaultTreatment: String
}

/// indicates feature flag changes
struct TargetingRuleUpdateNotification: NotificationTypeField {
    var entityType: NotificationType?
    var type: NotificationType {
        guard let notificationType = entityType else {
            return .unknown
        }
        return notificationType
    }

    let changeNumber: Int64
    let previousChangeNumber: Int64?
    let definition: String?
    let compressionType: CompressionType?

    init(
        changeNumber: Int64,
        previousChangeNumber: Int64? = nil,
        definition: String? = nil,
        compressionType: CompressionType? = nil) {
        self.changeNumber = changeNumber
        self.previousChangeNumber = previousChangeNumber
        self.definition = definition
        self.compressionType = compressionType
    }

    enum CodingKeys: String, CodingKey {
        case changeNumber
        case previousChangeNumber = "pcn"
        case definition = "d"
        case compressionType = "c"
    }
}

typealias SplitsUpdateNotification =
    TargetingRuleUpdateNotification // TODO: Temporary alias to be removed in follow-up PR

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
        return code >= 40140 && code <= 40149
    }

    var shouldIgnore: Bool {
        return !(code >= 40000 && code <= 49999)
    }
}
