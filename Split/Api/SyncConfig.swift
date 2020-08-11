//
//  SyncConfig.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@objc public class SyncConfig: NSObject {
    private (set) var filters: [SplitFilter]

    init(filters: [SplitFilter]) {
        self.filters = filters
    }

    @objc(builder)
    public static func builder() -> Builder {
        return Builder()
    }

    @objc(SyncConfigBuilder)
    public class Builder: NSObject {
        private let splitValidator = SplitNameValidator()
        private var builderFilters = [SplitFilter]()

        @objc(build)
        public func build() -> SyncConfig {
            var validatedFilters = [SplitFilter]()
            builderFilters.forEach { filter in
                let validatedValues = filter.values.filter { value in
                 if self.splitValidator.validate(name: value) != nil {
                     Logger.w("Warning: Malformed value in filter ignored: \(value)")
                     return false
                 }
                 return true
                }
                if validatedValues.count > 0 {
                    validatedFilters.append(SplitFilter(type: filter.type, values: validatedValues))
                } else {
                    Logger.w("Warning: filter of type \(filter.type) is empty. The filter is ignored")
                }
            }
            return SyncConfig(filters: validatedFilters)
        }

        @discardableResult
        @objc(addSplitFilter:)
        public func addSplitFilter(_ filter: SplitFilter) -> SyncConfig.Builder {
            builderFilters.append(filter)
            return self
        }
    }
}
