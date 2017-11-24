//
//  ConditionType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum ConditionType: Int {
    case Whitelist
    case Rollout
    
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
