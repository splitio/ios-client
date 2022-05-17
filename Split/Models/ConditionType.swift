//
//  ConditionType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
// swiftlint:disable inclusive_language
public enum ConditionType: Int, Codable {
    case whitelist
    case rollout

    public typealias RawValue = Int

    enum CodingKeys: String, CodingKey {
        case intValue
    }

    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = ConditionType.enumFromString(string: stringValue ?? "whitelist") ?? .whitelist
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .whitelist:
            try container.encode("whitelist")
        case .rollout:
            try container.encode("rollout")
        }
    }

    static func enumFromString(string: String) -> ConditionType? {
        switch string.lowercased() {
        case "whitelist":
            return ConditionType.whitelist
        case "rollout":
            return ConditionType.rollout
        default:
            return nil
        }
    }
}
