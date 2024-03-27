//
//  LocalhostSplitsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 05/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class LocalhostSplitsStorage: SplitsStorage {

    var changeNumber: Int64 = -1
    var updateTimestamp: Int64 = 1
    var splitsFilterQueryString: String = ""

    private let inMemorySplits = ConcurrentDictionary<String, SplitDTO>()

    init() {
    }

    func loadLocal() {
    }

    func get(name: String) -> SplitDTO? {
        return inMemorySplits.value(forKey: name)
    }

    func getMany(splits: [String]) -> [String: SplitDTO] {
        let names = Set(splits)
        return self.inMemorySplits.all.filter { return names.contains($0.key) }
    }

    func getAll() -> [String: SplitDTO] {
        return self.inMemorySplits.all
    }

    func update(splitChange: ProcessedSplitChange) -> Bool {
        var values = [String: SplitDTO]()
        splitChange.activeSplits.forEach {
            if let name = $0.name {
                values[name] = $0
            }
        }
        inMemorySplits.removeAll()
        inMemorySplits.setValues(values)
        return true
    }

    func update(filterQueryString: String) {
    }

    func update(bySetsFilter: SplitFilter?) {
    }

    func updateWithoutChecks(split: SplitDTO) {
    }

    func isValidTrafficType(name: String) -> Bool {
        return true
    }

    func clear() {
        inMemorySplits.removeAll()
    }

    func getCount() -> Int {
        return inMemorySplits.count
    }

    func destroy() {
        inMemorySplits.removeAll()
    }
}
