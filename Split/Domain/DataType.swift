//
//  DataType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum DataType: Int {
    case Number
    case DateTime
    case String
    
    static func enumFromString(string: String) -> DataType? {
        switch string.lowercased() {
        case "number":
            return DataType.Number
        case "datetime":
            return DataType.DateTime
        case "string":
            return DataType.String
        default:
            return nil
        }
    }
    
}
