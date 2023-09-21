//
//  FilterBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum FilterError: Error {
    case maxFilterValuesExceded(message: String)
    case byNamesAndBySetsUsed(message: String)
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
        var filterCounts: [SplitFilter.FilterType: Int] = [:]
        let types = Dictionary(grouping: filters, by: {$0.type}).keys
        types.forEach { filterType in
            let values = filters.filter({ $0.type == filterType }).flatMap({$0.values})
            filterCounts[filterType] = values.count
            groupedFilters.append(
                SplitFilter(type: filterType, values: values)
            )
        }
        if (filterCounts[.byName] ?? 0) > 0, (filterCounts[.bySet] ?? 0) > 0 {
            let message = "SDK Config: names and sets filter cannot be used at the same time."
            Logger.e(message)
            throw FilterError.byNamesAndBySetsUsed(message: message)
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
                Error: \(filter.type.maxValuesCount) different feature flag \(filter.type.queryStringField)
                can be specified at most. You passed \(filter.values.count)
                . Please consider reducing the amount or using prefixes to target specific groups of feature flags.
                """
                Logger.e(message)
                throw FilterError.maxFilterValuesExceded(message: message)
            }
            queryString.append("&\(filter.type.queryStringField)=\(deduptedValues.sorted().joined(separator: ","))")
        }
        return queryString

    }

    private func validateSetValues(_ values: String) {

    }

    private func validateSetValue(_ value: String) -> Bool {
        let pattern = "^[a-zA-Z0-9][a-zA-Z0-9_]{0,49}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex?.firstMatch(in: value, options: [], range: range) != nil
    }

    private func removeDuplicates(values: [String]) -> [String] {
        return Array(Set(values))
    }
}
