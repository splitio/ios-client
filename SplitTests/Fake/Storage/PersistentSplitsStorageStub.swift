//
//  PersistentSplitsStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentSplitsStorageStub: PersistentSplitsStorage {

    var changeNumber: Int64 = -1
    var updateTimestamp: Int64 = 0

    var snapshot: SplitsSnapshot = SplitsSnapshot(changeNumber: -1, splits: [Split](),
                                                  updateTimestamp: -1, splitsFilterQueryString: "", flagsSpec: "")

    var processedSplitChange: ProcessedSplitChange?

    var getAllCalled = false
    var updateCalled = false
    var deleteCalled = false
    var clearCalled = false
    var closeCalled = false
    var updateSplitCalled = false
    var deletedSplits = [String]()
    
    var filterQueryString = ""
    var flagsSpec = ""
    var updateFlagsSpecCalled = false
    var splits = [String: Split]()
    var lastBySetSplitFilter: SplitFilter?

    func getFilterQueryString() -> String {
        return snapshot.splitsFilterQueryString
    }

    func getFlagsSpec() -> String {
        return snapshot.flagsSpec
    }

    func update(splitChange: ProcessedSplitChange) {
        processedSplitChange = splitChange
        updateCalled = true
    }

    func update(split: Split) {
        updateSplitCalled  = true
        splits[split.name ?? ""] = split
        snapshot = SplitsSnapshot(changeNumber: snapshot.changeNumber, splits: splits.values.compactMap { $0 },
                                  updateTimestamp: snapshot.updateTimestamp, splitsFilterQueryString: filterQueryString,
                                  flagsSpec: flagsSpec)
    }
    
    func update(filterQueryString: String) {
        self.filterQueryString = filterQueryString
        snapshot = SplitsSnapshot(changeNumber: snapshot.changeNumber, splits: snapshot.splits,
                                  updateTimestamp: snapshot.updateTimestamp, splitsFilterQueryString: filterQueryString,
                                  flagsSpec: flagsSpec)
    }

    func update(flagsSpec: String) {
        self.flagsSpec = flagsSpec
        snapshot = SplitsSnapshot(changeNumber: snapshot.changeNumber, splits: snapshot.splits, updateTimestamp: snapshot.updateTimestamp, splitsFilterQueryString: filterQueryString, flagsSpec: flagsSpec)
        self.updateFlagsSpecCalled = true
    }

    func getSplitsSnapshot() -> SplitsSnapshot {
        return snapshot
    }

    func getAll() -> [Split] {
        getAllCalled = true
        return snapshot.splits
    }

    func delete(splitNames: [String]) {
        deleteCalled = true
        deletedSplits.append(contentsOf: splitNames)
    }

    func clear() {
        clearCalled = true
    }

    func close() {
        closeCalled = true
    }
    
    func getChangeNumber() -> Int64 {
        return changeNumber
    }

    func getUpdateTimestamp() -> Int64 {
        return updateTimestamp
    }

    var updateBySetsFilterCalled = false
    func update(bySetsFilter: SplitFilter?) {
        updateBySetsFilterCalled = true
        lastBySetSplitFilter = bySetsFilter
    }

    var getBySetsFilterCalled = true
    func getBySetsFilter() -> SplitFilter? {
        getBySetsFilterCalled = false
        return nil
    }
}
