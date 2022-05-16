//
//  MatcherType.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
// swiftlint:disable inclusive_language
enum MatcherType: String, Codable {

    case allKeys = "ALL_KEYS"
    case inSegment = "IN_SEGMENT"
    case whitelist = "WHITELIST"

    /* Numeric Matcher */
    case equalTo = "EQUAL_TO"
    case greaterThanOrEqualTo = "GREATER_THAN_OR_EQUAL_TO"
    case lessThanOrEqualTo = "LESS_THAN_OR_EQUAL_TO"
    case between = "BETWEEN"

    /* Set Matcher */
    case equalToSet = "EQUAL_TO_SET"
    case containsAnyOfSet = "CONTAINS_ANY_OF_SET"
    case containsAllOfSet = "CONTAINS_ALL_OF_SET"
    case partOfSet = "PART_OF_SET"

    /* String Matcher */
    case startsWith = "STARTS_WITH"
    case endsWith = "ENDS_WITH"
    case containsString = "CONTAINS_STRING"
    case matchesString = "MATCHES_STRING"

    /* Boolean Matcher */
    case equalToBoolean = "EQUAL_TO_BOOLEAN"

    /* Dependency Matcher */
    case dependency = "IN_SPLIT_TREATMENT"
}
