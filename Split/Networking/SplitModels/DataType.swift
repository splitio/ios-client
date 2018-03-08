//
//  DataType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum DataType: Int {
    
    case Number
    case DateTime
    
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
