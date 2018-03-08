//
//  Status.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum Status: Int {
    
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
