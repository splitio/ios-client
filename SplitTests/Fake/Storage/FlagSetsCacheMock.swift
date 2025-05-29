//
//  FlagSetsCacheMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 29/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class FlagSetsCacheMock: FlagSetsCache {
    var setsInFilter: Set<String>?

    var flagSets: [String: Set<String>] = [:]

    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>] {
        let setsFilter = Set(sets)
        let res = flagSets.filter {
            setsFilter.contains($0.key)
        }
        return res
    }

    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String] {
        let setsFilter = Set(sets)
        let res = flagSets.filter {
            setsFilter.contains($0.key)
        }
        let res1 = res.values.reduce([String]()) { $0 + $1 }
        return res1
    }

    func addToFlagSets(_ featureFlag: Split) {
        guard let name = featureFlag.name else {
            return
        }
        featureFlag.sets?.forEach { flagSet in
            flagSets[name] = Set([flagSet])
        }
    }

    func removeFromFlagSets(featureFlagName: String, sets: Set<String>) {
        sets.forEach { flagSet in
            flagSets[featureFlagName] = nil
        }
    }
}
