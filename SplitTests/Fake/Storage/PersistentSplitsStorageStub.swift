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

    var updateCalled = false
    var deleteCalled = false
    var clearCalled = false
    var closeCalled = false
    var updateSplitCalled = false
    
    var filterQueryString = ""

    func getFilterQueryString() -> String {
        return snapshot.splitsFilterQueryString
    }

    func update(splitChange: ProcessedSplitChange) {
        processedSplitChange = splitChange
        updateCalled = true
    }

    func update(split: Split) {
        updateSplitCalled  = true
    }
    
    func update(filterQueryString: String) {
        self.filterQueryString = filterQueryString
    }

    func getSplitsSnapshot() -> SplitsSnapshot {
        return snapshot
    }

    func getAll() -> [Split] {
        return snapshot.splits
    }

    func delete(splitNames: [String]) {
        deleteCalled = false
    }

    func clear() {
        clearCalled = false
    }

    func close() {
        closeCalled = false
    }
}
