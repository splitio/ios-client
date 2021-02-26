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

    var snapshot: SplitsSnapshot = SplitsSnapshot(changeNumber: -1, splits: [Split](),
                                                  updateTimestamp: -1, splitsFilterQueryString: "")

    var processedSplitChange: ProcessedSplitChange?

    var getAllCalled = false
    var updateCalled = false
    var deleteCalled = false
    var clearCalled = false
    var closeCalled = false
    var updateSplitCalled = false
    
    var filterQueryString = ""
    var splits = [String: Split]()

    func getFilterQueryString() -> String {
        return snapshot.splitsFilterQueryString
    }

    func update(splitChange: ProcessedSplitChange) {
        processedSplitChange = splitChange
        updateCalled = true
    }

    func update(split: Split) {
        updateSplitCalled  = true
        splits[split.name ?? ""] = split
        snapshot = SplitsSnapshot(changeNumber: snapshot.changeNumber, splits: splits.values.compactMap { $0 },
                                  updateTimestamp: snapshot.updateTimestamp, splitsFilterQueryString: filterQueryString)
    }
    
    func update(filterQueryString: String) {
        self.filterQueryString = filterQueryString
        snapshot = SplitsSnapshot(changeNumber: snapshot.changeNumber, splits: snapshot.splits,
                                  updateTimestamp: snapshot.updateTimestamp, splitsFilterQueryString: filterQueryString)
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
    }

    func clear() {
        clearCalled = true
    }

    func close() {
        closeCalled = true
    }
}
