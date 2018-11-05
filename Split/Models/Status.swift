//
//  Status.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum Status: Int, Codable {
    
    public typealias RawValue = Int
    
    enum CodingKeys: String, CodingKey {
        case intValue
    }
    
    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = Status.enumFromString(string: stringValue ?? "active") ?? .Archived
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .Active:
            try container.encode("active")
        case .Archived:
            try container.encode("archived")
        }
    }
    
    
    case Active
    case Archived
    
    static func enumFromString(string: String) -> Status? {
        switch string.lowercased() {
        case "active":
            return Status.Active
        case "archived":
            return Status.Archived
        default:
            return nil
        }
    }
}
