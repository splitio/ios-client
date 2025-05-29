//
//  SplitDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitDaoStub: SplitDao {
    var insertedSplits = [Split]()
    var splits = [Split]()
    var deletedSplits: [String]?
    var deleteAllCalled = false

    func insertOrUpdate(splits: [Split]) {
        insertedSplits = splits
    }

    func syncInsertOrUpdate(split: Split) {
        insertOrUpdate(split: split)
    }

    func insertOrUpdate(split: Split) {
        insertedSplits.append(split)
    }

    func getAll() -> [Split] {
        return splits
    }

    func delete(_ splits: [String]) {
        deletedSplits = splits
    }

    func deleteAll() {
        deleteAllCalled = true
    }
}
