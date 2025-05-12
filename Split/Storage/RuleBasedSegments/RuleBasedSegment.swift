//
//  RuleBasedSegment.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation

// MARK: - SegmentType Enum
@objc enum SegmentType: Int, Codable {
    case standard
    case ruleBased
    case large
    case unknown

    static func enumFromString(string: String) -> SegmentType? {
        switch string.lowercased() {
        case "standard":
            return .standard
        case "rule-based":
            return .ruleBased
        case "large":
            return .large
        default:
            return nil
        }
    }

    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = SegmentType.enumFromString(string: stringValue ?? "") ?? .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .standard:
            try container.encode("standard")
        case .ruleBased:
            try container.encode("rule-based")
        case .large:
            try container.encode("large")
        case .unknown:
            try container.encodeNil()
        }
    }
}

class ExcludedSegment: NSObject, Codable {
    var name: String?
    var type: SegmentType?

    enum CodingKeys: String, CodingKey {
        case name
        case type
    }

    override init() {
        super.init()
    }

    init(name: String? = nil, type: SegmentType? = nil) {
        self.name = name
        self.type = type
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(SegmentType.self, forKey: .type)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(name, forKey: .name)
    }

    func isStandard() -> Bool {
        return type == .standard
    }

    func isRuleBased() -> Bool {
        return type == .ruleBased
    }

    func isLarge() -> Bool {
        return type == .large
    }
}

class Excluded: NSObject, Codable {
    var keys: Set<String>?
    var segments: Set<ExcludedSegment>?

    enum CodingKeys: String, CodingKey {
        case keys
        case segments
    }

    override init() {
        super.init()
    }

    init(keys: Set<String>? = nil, segments: Set<ExcludedSegment>? = nil) {
        self.keys = keys
        self.segments = segments
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decodeIfPresent(Set<String>.self, forKey: .keys)
        segments = try container.decodeIfPresent(Set<ExcludedSegment>.self, forKey: .segments)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(keys, forKey: .keys)
        try container.encodeIfPresent(segments, forKey: .segments)
    }
}

class RuleBasedSegment: NSObject, Codable {
    var name: String?
    var trafficTypeName: String?
    var changeNumber: Int64 = -1
    var status: Status?
    var conditions: [Condition]?
    var excluded: Excluded?

    // Non-serialized properties for internal use
    var json: String = ""
    var isParsed: Bool = false

    enum CodingKeys: String, CodingKey {
        case name
        case trafficTypeName
        case changeNumber
        case status
        case conditions
        case excluded
    }

    override init() {
        super.init()
    }

    init(name: String, trafficTypeName: String? = nil, changeNumber: Int64 = -1, status: Status = .active, conditions: [Condition]? = nil, excluded: Excluded? = nil) {
        self.name = name
        self.trafficTypeName = trafficTypeName
        self.changeNumber = changeNumber
        self.status = status
        self.conditions = conditions
        self.excluded = excluded
        self.isParsed = true
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        trafficTypeName = try container.decodeIfPresent(String.self, forKey: .trafficTypeName)
        changeNumber = try container.decodeIfPresent(Int64.self, forKey: .changeNumber) ?? -1
        status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .active
        conditions = try container.decodeIfPresent([Condition].self, forKey: .conditions)
        excluded = try container.decodeIfPresent(Excluded.self, forKey: .excluded)
        isParsed = true
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(trafficTypeName, forKey: .trafficTypeName)
        try container.encode(changeNumber, forKey: .changeNumber)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(conditions, forKey: .conditions)
        try container.encodeIfPresent(excluded, forKey: .excluded)
    }
}

struct RuleBasedSegmentsSnapshot {
    let changeNumber: Int64
    let segments: [RuleBasedSegment]

    init(changeNumber: Int64, segments: [RuleBasedSegment]) {
        self.changeNumber = changeNumber
        self.segments = segments
    }
}
