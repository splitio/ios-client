//
//  MatcherType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum MatcherType: String {
    
    case AllKeys
    case InSegment
    case Whitelist
    
    /* Numeric Matcher */
    case EqualTo
    case GreaterThanOrEqualTo
    case LessThanOrEqualTo
    case Between
    
    /* Set Matcher */
    case EqualToSet
    case ContainsAnyOfSet
    case ContainsAllOfSet
    case PartOfSet
    
    /* String Matcher */
    case StartsWith
    case EndsWith
    case ContainsString
    case MatchesString
    
    /* Boolean Matcher */
    case EqualToBoolean
    
    /* Dependency Matcher */
    case InSplitTreatment
    
    static func enumFromString(string: String) -> MatcherType? {
        switch string.lowercased() {
        case "all_keys":
            return MatcherType.AllKeys
        case "in_segment":
            return MatcherType.InSegment
        case "whitelist":
            return MatcherType.Whitelist
        case "equal_to":
            return MatcherType.EqualTo
        case "greater_than_or_equal_to":
            return MatcherType.GreaterThanOrEqualTo
        case "less_than_or_equal_to":
            return MatcherType.LessThanOrEqualTo
        case "between":
            return MatcherType.Between
        case "equal_to_set":
            return MatcherType.EqualToSet
        case "contains_any_of_set":
            return MatcherType.ContainsAnyOfSet
        case "contains_all_of_set":
            return MatcherType.ContainsAllOfSet
        case "part_of_set":
            return MatcherType.PartOfSet
        case "starts_with":
            return MatcherType.StartsWith
        case "ends_with":
            return MatcherType.EndsWith
        case "contains_string":
            return MatcherType.ContainsString
        case "matches_string":
            return MatcherType.MatchesString
        case "equal_to_boolean":
            return MatcherType.EqualToBoolean
        case "in_split_treatment":
            return MatcherType.InSplitTreatment
        default:
            return nil
        }
    }
}
