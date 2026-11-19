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
    /// Applies `batch` in order, as if `addToFlagSets(_:)` was called for each flag, but with one lock
    /// acquisition. `previousSets` are the sets the caller knows the flag was indexed under before this
    /// change (nil when unknown). They are only used when `usePreviousSets` is true, to avoid scanning
    /// every set of the index for each flag.
    func addToFlagSets(_ batch: [(flag: Split, previousSets: Set<String>?)], usePreviousSets: Bool)
    func removeFromFlagSets(featureFlagName: String, sets: Set<String>)
}

class DefaultFlagSetsCache: FlagSetsCache, @unchecked Sendable {
    private(set) var setsInFilter: Set<String>?
    private var flagSets = [String: Set<String>]()
    private let lock = NSLock()

    init(setsInFilter: Set<String>?) {
        self.setsInFilter = setsInFilter
    }

    private func snapshot() -> [String: Set<String>] {
        lock.lock()
        defer { lock.unlock() }
        return flagSets
    }

    func getFeatureFlagNamesBySet(byFlagSets sets: [String]) -> [String: Set<String>] {
        let values = sets.asSet()
        return snapshot().filter { setValue, _ in
            return values.contains(setValue)
        }
    }

    func getFeatureFlagNames(forFlagSets sets: [String]) -> [String] {
        return Array(getFeatureFlagNamesBySet(byFlagSets: sets).values.reduce(Set<String>()) {
            $0.union($1)
        })
    }

    // Legacy single flag path: insert, then scan every set of the index. Kept as the reference behaviour
    // and as the fallback of the batch path.
    func addToFlagSets(_ featureFlag: Split) {
        addToFlagSets([(flag: featureFlag, previousSets: nil)], usePreviousSets: false)
    }

    func addToFlagSets(_ batch: [(flag: Split, previousSets: Set<String>?)], usePreviousSets: Bool) {
        lock.lock()
        defer { lock.unlock() }

        // Cold load: nothing indexed at batch start, so a flag not yet seen in this batch has no entry to clean.
        let indexWasEmpty = flagSets.isEmpty
        var seenNames = Set<String>()

        for (featureFlag, previousSets) in batch {
            guard let name = featureFlag.name else {
                continue
            }

            let sets = featureFlag.sets ?? [].asSet()
            for flagSet in sets {
                if setsInFilter == nil || (setsInFilter?.contains(flagSet) ?? false) {
                    flagSets[flagSet, default: []].insert(name)
                }
            }

            if usePreviousSets, let previous = previousSets {
                for flagSet in previous.subtracting(sets) {
                    remove(name, from: flagSet)
                }
            } else if usePreviousSets, indexWasEmpty, !seenNames.contains(name) {
                // cold load, nothing to remove
            } else {
                for flagSet in Array(flagSets.keys) where !sets.contains(flagSet) {
                    remove(name, from: flagSet)
                }
            }
            seenNames.insert(name)
        }
    }

    func removeFromFlagSets(featureFlagName: String, sets: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        let targets = sets.count > 0 ? sets : Set(flagSets.keys)
        targets.forEach { remove(featureFlagName, from: $0) }
    }

    // Caller holds the lock. A set without members does not exist in the index.
    private func remove(_ name: String, from flagSet: String) {
        guard var names = flagSets[flagSet] else {
            return
        }
        names.remove(name)
        flagSets[flagSet] = names.isEmpty ? nil : names
    }
}
