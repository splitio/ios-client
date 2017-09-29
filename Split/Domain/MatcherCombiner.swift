//
//  MatcherCombiner.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum MatcherCombiner: Int {
    case And
    case Or
    
    static func enumFromString(string: String) -> MatcherCombiner? {
        switch string.lowercased() {
        case "and":
            return MatcherCombiner.And
        case "or":
            return MatcherCombiner.Or
        default:
            return nil
        }
    }
}
