//
//  Status.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc enum Status: Int, Codable {

    public typealias RawValue = Int

    enum CodingKeys: String, CodingKey {
        case intValue
    }

    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = Status.enumFromString(string: stringValue ?? "active") ?? .archived
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .active:
            try container.encode("active")
        case .archived:
            try container.encode("archived")
        }
    }

    case active
    case archived

    static func enumFromString(string: String) -> Status? {
        switch string.lowercased() {
        case "active":
            return Status.active
        case "archived":
            return Status.archived
        default:
            return nil
        }
    }
}
