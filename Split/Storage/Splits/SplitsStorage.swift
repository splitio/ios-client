//
//  SplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 11/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SyncSplitsStorage: RolloutDefinitionsCache {
    func update(splitChange: ProcessedSplitChange) -> Bool
}

protocol SplitsStorage: SyncSplitsStorage {
    var changeNumber: Int64 { get }
    var updateTimestamp: Int64 { get }
    var segmentsInUse: Int64 { get }

    func loadLocal()
    func get(name: String) -> Split?
    func getMany(splits: [String]) -> [String: Split]
    func getAll() -> [String: Split]
    func update(splitChange: ProcessedSplitChange) -> Bool
    func update(bySetsFilter: SplitFilter?)
    func updateWithoutChecks(split: Split)
    func isValidTrafficType(name: String) -> Bool
    func getCount() -> Int
    func destroy()
}

class DefaultSplitsStorage: SplitsStorage {

    private var persistentStorage: PersistentSplitsStorage
    private var inMemorySplits: ConcurrentDictionary<String, Split>
    private var trafficTypes: ConcurrentDictionary<String, Int>
    private let flagSetsCache: FlagSetsCache
    internal var segmentsInUse: Int64 = 0
    
    private(set) var changeNumber: Int64 = -1
    private(set) var updateTimestamp: Int64 = -1

    init(persistentSplitsStorage: PersistentSplitsStorage,
         flagSetsCache: FlagSetsCache) {
        self.persistentStorage = persistentSplitsStorage
        self.inMemorySplits = ConcurrentDictionary()
        self.trafficTypes = ConcurrentDictionary()
        self.flagSetsCache = flagSetsCache
    }

    func loadLocal() {
        
        // Ensure count of Flags with Segments (for optimization feature)
        segmentsInUse = persistentStorage.getSegmentsInUse()
        defer { persistentStorage.update(segmentsInUse: segmentsInUse) }
        
        let snapshot = persistentStorage.getSplitsSnapshot()
        let active = snapshot.splits.filter { $0.status == .active }
        let archived = snapshot.splits.filter { $0.status == .archived }
        _ = processUpdated(splits: active, active: true)
        _ = processUpdated(splits: archived, active: false)
        changeNumber = snapshot.changeNumber
        updateTimestamp = snapshot.updateTimestamp
    }

    func get(name: String) -> Split? {
        let lowercasedName = name.lowercased()
        
        guard let split = inMemorySplits.value(forKey: lowercasedName) else {
            return nil
        }
        if !split.isCompletelyParsed {
            if let parsed = try? Json.decodeFrom(json: split.json, to: Split.self) {
                if isUnsupportedMatcher(split: parsed) {
                    parsed.conditions = [SplitHelper.createDefaultCondition()]
                }

                parsed.isCompletelyParsed = true
                inMemorySplits.setValue(parsed, forKey: lowercasedName)
                return parsed
            }
            return nil
        } else if isUnsupportedMatcher(split: split) {
            split.conditions = [SplitHelper.createDefaultCondition()]
        }
        return split
    }

    func getMany(splits: [String]) -> [String: Split] {
        let filter = Set(splits.compactMap { $0.lowercased() })
        return inMemorySplits.all.filter { splitName, _ in return filter.contains(splitName) }
    }

    func getAll() -> [String: Split] {
        return inMemorySplits.all
    }

    func update(splitChange: ProcessedSplitChange) -> Bool {
        
        // Ensure count of Flags with Segments (for optimization feature)
        segmentsInUse = persistentStorage.getSegmentsInUse()
        defer { persistentStorage.update(segmentsInUse: segmentsInUse) }
        
        // Process
        let updated = processUpdated(splits: splitChange.activeSplits, active: true)
        let removed = processUpdated(splits: splitChange.archivedSplits, active: false)

        // Update
        changeNumber = splitChange.changeNumber
        updateTimestamp = splitChange.updateTimestamp
        persistentStorage.update(splitChange: splitChange)

        return updated || removed
    }

    func update(bySetsFilter filter: SplitFilter?) {
        self.persistentStorage.update(bySetsFilter: filter)
    }

    func updateWithoutChecks(split: Split) {
        if let splitName = split.name?.lowercased() {
            inMemorySplits.setValue(split, forKey: splitName)
            persistentStorage.update(split: split)
        }
    }

    func isValidTrafficType(name: String) -> Bool {
        return trafficTypes.value(forKey: name) != nil
    }

    func clear() {
        inMemorySplits.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }

    func getCount() -> Int {
        return inMemorySplits.count
    }

    private func processUpdated(splits: [Split], active: Bool) -> Bool {
        var cachedSplits = inMemorySplits.all
        var cachedTrafficTypes = trafficTypes.all
        var splitsUpdated = false
        var splitsRemoved = false

        for split in splits {
            guard let splitName = split.name?.lowercased()  else {
                Logger.e("Invalid feature flag name received while updating feature flags")
                continue
            }

            guard let trafficTypeName = split.trafficTypeName else {
                Logger.e("Invalid feature flag traffic type received while updating feature flags")
                continue
            }

            let loadedSplit = cachedSplits[splitName]

            if loadedSplit == nil, !active {
                // Split to remove not in memory, do nothing
                continue
            }
            
            // Keep count of Flags with Segments (used to optimize "/memberships" endpoint hits)
            if StorageHelper.usesSegments(split.conditions ?? []) {
                if inMemorySplits.value(forKey: splitName) == nil && active { // If new Split and active
                    segmentsInUse += 1
                } else if inMemorySplits.value(forKey: splitName) != nil && !active { // If known Split and archived
                    segmentsInUse -= 1
                }
            }

            if loadedSplit != nil, let oldTrafficType = loadedSplit?.trafficTypeName {
                // Must decrease old traffic type count if a feature flag is updated or removed
                let count = cachedTrafficTypes[oldTrafficType] ?? 0
                if count > 1 {
                    cachedTrafficTypes[oldTrafficType] = count - 1
                } else {
                    cachedTrafficTypes.removeValue(forKey: oldTrafficType)
                }
            }

            if active {
                cachedTrafficTypes[trafficTypeName] = (cachedTrafficTypes[trafficTypeName] ?? 0) + 1
                cachedSplits[splitName] = split
                flagSetsCache.addToFlagSets(split)
                splitsUpdated = true
            } else {
                cachedSplits.removeValue(forKey: splitName)
                splitsRemoved = true
                if let name = split.name {
                    flagSetsCache.removeFromFlagSets(featureFlagName: name, sets: flagSetsCache.setsInFilter ?? [])
                }
            }
        }
        inMemorySplits.setValues(cachedSplits)
        trafficTypes.setValues(cachedTrafficTypes)
        return splitsUpdated || splitsRemoved
    }

    func destroy() {
        inMemorySplits.removeAll()
    }

    private func isUnsupportedMatcher(split: Split?) -> Bool {
        var result = false
        guard let conditions = split?.conditions else {
            return false
        }

        result = conditions.contains { condition in
            guard let matcherGroup = condition.matcherGroup else {
                return false
            }

            guard let matchers = matcherGroup.matchers else {
                return false
            }

            return matchers.contains { matcher in
                matcher.matcherType == nil
            }
        }

        if result {
            Logger.w("Unable to create matcher for matcher type")
        }

        return result
    }
}

class BackgroundSyncSplitsStorage: SyncSplitsStorage {

    private var persistentStorage: PersistentSplitsStorage

    init(persistentSplitsStorage: PersistentSplitsStorage) {
        self.persistentStorage = persistentSplitsStorage
    }

    func update(splitChange: ProcessedSplitChange) -> Bool {
        persistentStorage.update(splitChange: splitChange)
        return true
    }

    func clear() {
        persistentStorage.clear()
    }
}


