//
//  MatcherType.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

enum MatcherType: String, Codable {

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
}
