//
//  SplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 11/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SplitsStorage {
    var changeNumber: Int64 { get set }
    var updateTimestamp: Int64 { get set }
    var splitsFilterQueryString: String { get set }

    func loadLocal()
    func get(name: String) -> Split?
    func getMany(splits: [String]) -> [String: Split]
    func getAll() -> [String: Split]
    func update(splitChange: ProcessedSplitChange)
    func updateWithoutChecks(split: Split)
    func isValidTrafficType(name: String) -> Bool
    func clear()
}

class DefaultSplitsStorage: SplitsStorage {
    private var persistentStorage: PersistentSplitsStorage
    private var inMemorySplits: SyncDictionarySingleWrapper<String, Split>
    private var trafficTypes: SyncDictionarySingleWrapper<String, Int>

    var changeNumber: Int64 = -1
    var updateTimestamp: Int64 = -1
    var splitsFilterQueryString: String = ""

    init(persistentSplitsStorage: PersistentSplitsStorage) {
        self.persistentStorage = persistentSplitsStorage
        self.inMemorySplits = SyncDictionarySingleWrapper()
        self.trafficTypes = SyncDictionarySingleWrapper()
    }

    func loadLocal() {
        let snapshot = persistentStorage.getSplitsSnapshot()
        snapshot.splits.forEach { split in
            guard let splitName = split.name else {
                return
            }
            inMemorySplits.setValue(split, forKey: splitName)
        }
        changeNumber = snapshot.changeNumber
        updateTimestamp = snapshot.updateTimestamp
        splitsFilterQueryString = snapshot.splitsFilterQueryString
    }

    func get(name: String) -> Split? {
        return inMemorySplits.value(forKey: name)
    }

    func getMany(splits: [String]) -> [String: Split] {
        let filter = Set(splits)
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

    func updateWithoutChecks(split: Split) {

    }

    func isValidTrafficType(name: String) -> Bool {
        return trafficTypes.value(forKey: name.lowercased()) != nil
    }

    func clear() {
        inMemorySplits.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }

    private func increaseTrafficTypeCount(name: String) {
        let lowercaseName = name.lowercased()
        let count = countForTrafficType(name: lowercaseName) + 1
        trafficTypes.setValue(count, forKey: lowercaseName)
    }

    private func decreaseTrafficTypeCount(name: String) {
        let lowercaseName = name.lowercased()

        let count = countForTrafficType(name: lowercaseName)
        if count > 1 {
            trafficTypes.setValue(count - 1, forKey: lowercaseName)
        } else {
            trafficTypes.removeValue(forKey: lowercaseName)
        }
    }

    private func countForTrafficType(name: String) -> Int {
        return trafficTypes.value(forKey: name) ?? 0
    }

    private func processUpdated(splits: [Split], active: Bool) {
        for split in splits {
            guard let splitName = split.name  else {
                Logger.e("Invalid split name received while updating splits")
                continue
            }

            guard let trafficTypeName = split.trafficTypeName else {
                Logger.e("Invalid split traffic type received while updating splits")
                continue
            }

            let loadedSplit = inMemorySplits.value(forKey: splitName)

            if loadedSplit == nil, !active {
                // Split to remove not in memory, do nothing
                continue
            }

            if loadedSplit != nil, let oldTrafficType = loadedSplit?.trafficTypeName {
                // Must decreated old traffic type count if a split is updated or removed
                decreaseTrafficTypeCount(name: oldTrafficType)
            }

            if active {
                increaseTrafficTypeCount(name: trafficTypeName)
                inMemorySplits.setValue(split, forKey: splitName)
            } else {
                inMemorySplits.removeValue(forKey: splitName)
            }
        }
    }
}
