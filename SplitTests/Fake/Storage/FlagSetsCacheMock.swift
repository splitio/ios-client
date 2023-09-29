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

    private var flagSets: [String: Set<String>] = [:]

    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>] {
        // Simplified mock implementation...
        return flagSets
    }

    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String] {
        // Simplified mock implementation...
        return Array(flagSets.keys)
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
