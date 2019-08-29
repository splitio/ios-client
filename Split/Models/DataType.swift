//
//  DataType.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

enum DataType: Int, Codable {

    case number
    case dateTime

    public typealias RawValue = Int

    enum CodingKeys: String, CodingKey {
        case intValue
    }

    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = DataType.enumFromString(string: stringValue ?? "number") ?? .number
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number:
            try container.encode("number")
        case .dateTime:
            try container.encode("datetime")
        }
    }

    static func enumFromString(string: String) -> DataType? {
        switch string.lowercased() {
        case "number":
            return DataType.number
        case "datetime":
            return DataType.dateTime
        default:
            return nil
        }
    }
}
