//
//  SplitDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import Foundation

class SplitDaoStub: SplitDao {
    var insertedSplits = [SplitDTO]()
    var splits = [SplitDTO]()
    var deletedSplits: [String]?
    var deleteAllCalled = false
    
    func insertOrUpdate(splits: [SplitDTO]) {
        insertedSplits = splits
    }

    func syncInsertOrUpdate(split: SplitDTO) {
       insertOrUpdate(split: split)
    }
    
    func insertOrUpdate(split: SplitDTO) {
        insertedSplits.append(split)
    }
    
    func getAll() -> [SplitDTO] {
        return splits
    }
    
    func delete(_ splits: [String]) {
        deletedSplits = splits
    }
    
    func deleteAll() {
        deleteAllCalled = true
    }
}
