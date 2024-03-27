//
//  SplitsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitsStorageStub: SplitsStorage {

    var updatedSplitChange: ProcessedSplitChange? = nil
    
    var changeNumber: Int64 = 0
    
    var updateTimestamp: Int64 = 0
    
    var splitsFilterQueryString: String = ""

    var loadLocalCalled = false
    var clearCalled = false

    var updatedWithoutChecksSplit: SplitDTO?
    var updatedWithoutChecksExp: XCTestExpectation?

    var getCountCalledCount = 0

    private let inMemorySplits = ConcurrentDictionary<String, SplitDTO>()

    func loadLocal() {
        loadLocalCalled = true
    }
    
    func get(name: String) -> SplitDTO? {
        return inMemorySplits.value(forKey: name.lowercased())
    }
    
    func getMany(splits: [String]) -> [String : SplitDTO] {
        let names = Set(splits.compactMap { $0.lowercased() })
        return inMemorySplits.all.filter { return names.contains($0.key) }
    }
    
    func getAll() -> [String : SplitDTO] {
        return inMemorySplits.all
    }

    var updateSplitChangeCalled = false
    var splitsWereUpdated = false
    func update(splitChange: ProcessedSplitChange) -> Bool {
        updatedSplitChange = splitChange
        let active = splitChange.activeSplits
        let archived = splitChange.archivedSplits
        changeNumber = splitChange.changeNumber
        updateTimestamp = splitChange.updateTimestamp
        active.forEach {
            inMemorySplits.setValue($0, forKey: $0.name?.lowercased() ?? "")
        }
        archived.forEach {
            inMemorySplits.removeValue(forKey: $0.name?.lowercased() ?? "")
        }
        updateSplitChangeCalled = true
        return splitsWereUpdated
    }
    
    func update(filterQueryString: String) {
        self.splitsFilterQueryString = filterQueryString
    }
    
    func updateWithoutChecks(split: SplitDTO) {
        inMemorySplits.setValue(split, forKey: split.name ?? "")
        updatedWithoutChecksSplit = split
        if let exp = updatedWithoutChecksExp {
            exp.fulfill()
        }
    }
    
    func isValidTrafficType(name: String) -> Bool {
        let splits = inMemorySplits.all.compactMap { return $0.value }
        let count =  splits.filter { return $0.trafficTypeName == name && $0.status == .active }.count
        return count > 0
    }
    
    func clear() {
        clearCalled = true
        inMemorySplits.removeAll()
    }

    func destroy() {
        inMemorySplits.removeAll()
    }

    func getCount() -> Int {
        getCountCalledCount+=1
        return inMemorySplits.count
    }

    var updateBySetsFilterCount = 0
    func update(bySetsFilter: SplitFilter?) {
        updateBySetsFilterCount+=1
    }
}
