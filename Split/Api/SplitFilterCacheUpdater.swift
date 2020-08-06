//
//  SplitFilterCacheUpdater.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class SplitFilterCacheUpdater {
    static func update(filters: [SplitFilter], currentQueryString: String, splitCache: SplitCacheProtocol) {
        let kPrefixSeparator = "__"
        if currentQueryString != splitCache.getQueryString() {
            let splitsToKeep = filters.filter { $0.type == .byName} .flatMap { $0.values }
            let prefixToKeep = filters.filter { $0.type == .byPrefix} .flatMap { $0.values }
            let splits = splitCache.getAllSplits()
            for split in splits {
                var prefix: String?
                guard let splitName = split.name else {
                    continue
                }

                if let prefixRange = splitName.range(of: kPrefixSeparator) {
                    prefix = String(splitName.prefix(upTo: prefixRange.lowerBound))
                }

                if !(splitsToKeep.filter { $0 == split.name } .count > 0),
                    (prefix == nil || !(prefixToKeep.filter { $0 == prefix } .count > 0)) {
                    splitCache.deleteSplit(name: splitName)
                }
            }
        }
    }
}
