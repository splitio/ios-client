//
//  FlagSetsCache.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FlagSetsCache {
    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>]
    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String]
    func addToFlagSets(_ featureFlag: Split)
    func removeFromFlagSets(featureFlagName: String, sets: Set<String>)
}

class DefaultFlagSetsCache: FlagSetsCache {
    private let setsInFilter: Set<String>?
    private let flagSets = SynchronizedDictionarySet<String, String>()

    init(setsInFilter: Set<String>?) {
        self.setsInFilter = setsInFilter
    }

    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>] {
        let values = sets.asSet()
        return flagSets.all.filter { setValue, _ in
            return values.contains(setValue)
        }
    }

    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String] {
        return Array(getFeatureFlagNamesBySet(byFlagSets: sets).values.reduce(Set<String>()) {
            $0.union($1)
        })
    }

    func addToFlagSets(_ featureFlag: Split) {
        guard let name = featureFlag.name else {
            return
        }

        featureFlag.sets?.forEach { flagSet in
            if setsInFilter == nil || (setsInFilter?.contains(flagSet) ?? false) {
                flagSets.insert(name, forKey: flagSet)
            }
        }
    }

    func removeFromFlagSets(featureFlagName: String, sets: Set<String>) {
        sets.forEach { flagSet in
            flagSets.removeValue(featureFlagName, forKey: flagSet)
        }
    }
}
