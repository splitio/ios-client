//
//  FilterBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class MaxFilterValuesExcededError: Error {
    var message: String
    init(message: String) {
        self.message = message
    }
}

class FilterBuilder {
    private var filters = [SplitFilter]()

    func add(filters: [SplitFilter]) -> Self {
        self.filters.append(contentsOf: filters)
        return self
    }

    func build() throws -> String {

        if filters.count == 0 {
            return ""
        }

        var groupedFilters = [SplitFilter]()
        let types = Dictionary(grouping: filters, by: {$0.type}).keys
        types.forEach { filterType in
            groupedFilters.append(
                SplitFilter(type: filterType, values: filters.filter({ $0.type == filterType }).flatMap({$0.values}))
            )
        }
        groupedFilters.sort(by: { $0.type.rawValue < $1.type.rawValue})
        var queryString = ""
        for filter in groupedFilters {
            let deduptedValues = removeDuplicates(values: filter.values)
            if deduptedValues.count == 0 {
                continue
            }
            if deduptedValues.count > filter.type.maxValuesCount {
                let message = """
                Error: \(filter.type.maxValuesCount) different split \(filter.type.queryStringField)
                can be specified at most. You passed \(filter.values.count)
                . Please consider reducing the amount or using prefixes to target specific groups of splits.
                """
                Logger.e(message)
                throw MaxFilterValuesExcededError(message: message)
            }
            queryString.append("&\(filter.type.queryStringField)=\(deduptedValues.sorted().joined(separator: ","))")
        }
        return queryString

    }

    private func removeDuplicates(values: [String]) -> [String] {
        return Array(Set(values))
    }
}
