//
//  FlagSetsCache.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FlagSetsCache {
    var setsInFilter: Set<String>? { get }
    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>]
    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String]
    func addToFlagSets(_ featureFlag: Split)
    func removeFromFlagSets(featureFlagName: String, sets: Set<String>)
}

class DefaultFlagSetsCache: FlagSetsCache {
    private(set) var setsInFilter: Set<String>?
    private let flagSets = SynchronizedDictionarySet<String, String>()

    init(setsInFilter: Set<String>?) {
        self.setsInFilter = setsInFilter
    }

    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>] {
        let values = sets.asSet()
        return flagSets.all.filter { setValue, _ in
            values.contains(setValue)
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

        let sets = featureFlag.sets ?? [].asSet()
        for flagSet in flagSets.keys {
            if !sets.contains(flagSet) {
                flagSets.removeValue(name, forKey: flagSet)
            }
        }
    }

    func removeFromFlagSets(featureFlagName: String, sets: Set<String>) {
        let allSets = flagSets.all.keys
        if !sets.isEmpty {
            sets.forEach { flagSet in
                flagSets.removeValue(featureFlagName, forKey: flagSet)
            }
        } else {
            allSets.forEach { flagSet in
                flagSets.removeValue(featureFlagName, forKey: flagSet)
            }
        }
    }
}
