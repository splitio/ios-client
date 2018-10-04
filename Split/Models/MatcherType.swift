//
//  MatcherType.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

public enum MatcherType: String, Codable {
    
    case AllKeys = "ALL_KEYS"
    case InSegment = "IN_SEGMENT"
    case Whitelist = "WHITELIST"
    
    /* Numeric Matcher */
    case EqualTo = "EQUAL_TO"
    case GreaterThanOrEqualTo = "GREATER_THAN_OR_EQUAL_TO"
    case LessThanOrEqualTo = "LESS_THAN_OR_EQUAL_TO"
    case Between = "BETWEEN"
    
    /* Set Matcher */
    case EqualToSet = "EQUAL_TO_SET"
    case ContainsAnyOfSet = "CONTAINS_ANY_OF_SET"
    case ContainsAllOfSet = "CONTAINS_ALL_OF_SET"
    case PartOfSet = "PART_OF_SET"
    
    /* String Matcher */
    case StartsWith = "STARTS_WITH"
    case EndsWith = "ENDS_WITH"
    case ContainsString = "CONTAINS_STRING"
    case MatchesString = "MATCHES_STRING"
    
    /* Boolean Matcher */
    case EqualToBoolean = "EQUAL_TO_BOOLEAN"
    
    /* Dependency Matcher */
    case Dependency = "IN_SPLIT_TREATMENT"
    
    /*
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
            return MatcherType.Dependency
        default:
            return nil
        }
    }
 */
}
