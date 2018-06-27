//
//  DataType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum DataType: Int, Codable {
    
    case Number
    case DateTime
    
    public typealias RawValue = Int
    
    enum CodingKeys: String, CodingKey {
        case intValue
    }
    
    public init(from decoder: Decoder) throws {
        let stringValue = try? decoder.singleValueContainer().decode(String.self)
        self = DataType.enumFromString(string: stringValue ?? "number") ?? .Number
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .Number:
            try container.encode("number")
        case .DateTime:
            try container.encode("datetime")
        }
    }
    
    static func enumFromString(string: String) -> DataType? {
        switch string.lowercased() {
        case "number":
            return DataType.Number
        case "datetime":
            return DataType.DateTime
        default:
            return nil
        }
    }   
}
