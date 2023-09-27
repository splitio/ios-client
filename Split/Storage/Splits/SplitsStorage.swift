//
//  SplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 11/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SyncSplitsStorage {
    func update(splitChange: ProcessedSplitChange)
    func clear()
}

protocol SplitsStorage: SyncSplitsStorage {
    var changeNumber: Int64 { get }
    var updateTimestamp: Int64 { get }
    var splitsFilterQueryString: String { get }

    func loadLocal()
    func get(name: String) -> Split?
    func getMany(splits: [String]) -> [String: Split]
    func getAll() -> [String: Split]
    func update(splitChange: ProcessedSplitChange)
    func update(filterQueryString: String)
    func update(bySetsFilter: SplitFilter?)
    func updateWithoutChecks(split: Split)
    func isValidTrafficType(name: String) -> Bool
    func getCount() -> Int
    func clear()
    func destroy()
}

class DefaultSplitsStorage: SplitsStorage {

    private var persistentStorage: PersistentSplitsStorage
    private var inMemorySplits: ConcurrentDictionary<String, Split>
    private var trafficTypes: ConcurrentDictionary<String, Int>

    private (set) var changeNumber: Int64 = -1
    private (set) var updateTimestamp: Int64 = -1
    private (set) var splitsFilterQueryString: String = ""

    init(persistentSplitsStorage: PersistentSplitsStorage) {
        self.persistentStorage = persistentSplitsStorage
        self.inMemorySplits = ConcurrentDictionary()
        self.trafficTypes = ConcurrentDictionary()
    }

    func loadLocal() {
        let snapshot = persistentStorage.getSplitsSnapshot()
        let active = snapshot.splits.filter { $0.status == .active }
        let archived = snapshot.splits.filter { $0.status == .archived }
        processUpdated(splits: active, active: true)
        processUpdated(splits: archived, active: false)
        changeNumber = snapshot.changeNumber
        updateTimestamp = snapshot.updateTimestamp
        splitsFilterQueryString = snapshot.splitsFilterQueryString
    }

    func get(name: String) -> Split? {
        return inMemorySplits.value(forKey: name.lowercased())
    }

    func getMany(splits: [String]) -> [String: Split] {
        let filter = Set(splits.compactMap { $0.lowercased() })
        return inMemorySplits.all.filter { splitName, _ in return filter.contains(splitName) }
    }

    func getAll() -> [String: Split] {
        return inMemorySplits.all
    }

    func update(splitChange: ProcessedSplitChange) {
        processUpdated(splits: splitChange.activeSplits, active: true)
        processUpdated(splits: splitChange.archivedSplits, active: false)

        changeNumber = splitChange.changeNumber
        updateTimestamp = splitChange.updateTimestamp
        persistentStorage.update(splitChange: splitChange)
    }

    func update(filterQueryString: String) {
        splitsFilterQueryString = filterQueryString
        self.persistentStorage.update(filterQueryString: filterQueryString)
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

    private func processUpdated(splits: [Split], active: Bool) {
        var cachedSplits = inMemorySplits.all
        var cachedTrafficTypes = trafficTypes.all

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

            if loadedSplit != nil, let oldTrafficType = loadedSplit?.trafficTypeName {
                // Must decreated old traffic type count if a feature flag is updated or removed
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
            } else {
                cachedSplits.removeValue(forKey: splitName)
            }
        }
        inMemorySplits.setValues(cachedSplits)
        trafficTypes.setValues(cachedTrafficTypes)
    }

    func destroy() {
        inMemorySplits.removeAll()
    }
}

class BackgroundSyncSplitsStorage: SyncSplitsStorage {

    private var persistentStorage: PersistentSplitsStorage

    init(persistentSplitsStorage: PersistentSplitsStorage) {
        self.persistentStorage = persistentSplitsStorage
    }

    func update(splitChange: ProcessedSplitChange) {
        persistentStorage.update(splitChange: splitChange)
    }

    func clear() {
        persistentStorage.clear()
    }
}
