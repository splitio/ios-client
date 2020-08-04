//
//  SyncConfig.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

public struct SyncConfig {
    private (set) var filters: [SplitFilter]

    init(filters: [SplitFilter]) {
        self.filters = filters
    }

    public static func builder() -> Builder {
        return Builder()
    }

    public class Builder {
        private let splitValidator = SplitNameValidator()
        private var builderFilters = [SplitFilter]()
        func build() -> SyncConfig {
            var validatedFilters = [SplitFilter]()
            builderFilters.forEach { filter in
                let validatedValues = filter.values.filter { value in
                 if self.splitValidator.validate(name: value) != nil {
                     Logger.w("Warning: Malformed \(value) value. Filter ignored: \(value)")
                     return false
                 }
                 return true
                }
                if validatedValues.count > 0 {
                    validatedFilters.append(SplitFilter(type: filter.type, values: validatedValues))
                }
            }
            return SyncConfig(filters: validatedFilters)
        }

        public func addSplitFilter(_ filter: SplitFilter) -> SyncConfig.Builder {
            builderFilters.append(filter)
            return self
        }
    }
}
