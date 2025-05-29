//
//  SplitFilter.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@objc public class SplitFilter: NSObject, Codable {
    enum FilterType: Int, Hashable, CustomStringConvertible, Codable {
        case bySet = 0
        case byName = 1
        case byPrefix = 2

        var description: String {
            switch self {
            case .byName:
                return "by split name"
            case .byPrefix:
                return "by split prefix"
            case .bySet:
                return "by split set"
            }
        }

        // Used to build query
        var queryStringField: String {
            switch self {
            case .bySet:
                return "sets"
            case .byName:
                return "names"
            case .byPrefix:
                return "prefixes"
            }
        }

        // Used to validate filter building
        var maxValuesCount: Int {
            switch self {
            case .byName:
                return 400
            case .byPrefix:
                return 50
            case .bySet:
                return 999999
            }
        }
    }

    private(set) var values: [String]
    private(set) var type: FilterType

    // This constructor is not private (but intern) to allow Split Sync Config builder be agnostic when creating filters
    // Also is not public to force SDK users to use static functions "byName" and "byPrefix"
    init(type: FilterType, values: [String]) {
        self.type = type
        self.values = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    @objc(byName:)
    public static func byName(_ values: [String]) -> SplitFilter {
        return SplitFilter(type: .byName, values: values)
    }

    @objc(byPrefix:)
    public static func byPrefix(_ values: [String]) -> SplitFilter {
        return SplitFilter(type: .byPrefix, values: values)
    }

    @objc(bySet:)
    public static func bySet(_ values: [String]) -> SplitFilter {
        return SplitFilter(type: .bySet, values: values)
    }
}
