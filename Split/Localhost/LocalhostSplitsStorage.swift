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
    var flagsSpec: String = ""
    internal var segmentsInUse: Int64 = 0

    private let inMemorySplits = ConcurrentDictionary<String, Split>()

    init() {
    }

    func loadLocal(forceReparse: Bool = false) {
    }

    func get(name: String) -> Split? {
        return inMemorySplits.value(forKey: name)
    }

    func getMany(splits: [String]) -> [String: Split] {
        let names = Set(splits)
        return self.inMemorySplits.all.filter { return names.contains($0.key) }
    }

    func getAll() -> [String: Split] {
        return self.inMemorySplits.all
    }

    func update(splitChange: ProcessedSplitChange) -> Bool {
        var values = [String: Split]()
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

    func update(flagsSpec: String) {
    }

    func update(bySetsFilter: SplitFilter?) {
    }

    func updateWithoutChecks(split: Split) {
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
    
    func forceReparsing() {
        
    }
}
