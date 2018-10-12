//
//  ConditionType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum ConditionType: Int, Codable {
    case Whitelist
    case Rollout
    
    public typealias RawValue = Int
    
    enum CodingKeys: String, CodingKey {
        case intValue
    }
    
    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = ConditionType.enumFromString(string: stringValue ?? "whitelist") ?? .Whitelist
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .Whitelist:
            try container.encode("whitelist")
        case .Rollout:
            try container.encode("rollout")
        }
    }
    
    static func enumFromString(string: String) -> ConditionType? {
        switch string.lowercased() {
        case "whitelist":
            return ConditionType.Whitelist
        case "rollout":
            return ConditionType.Rollout
        default:
            return nil
        }
    }
}
