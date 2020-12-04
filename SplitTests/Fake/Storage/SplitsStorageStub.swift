//
//  SplitsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitsStorageStub: SplitsStorage {
    
    var updatedSplitChange: ProcessedSplitChange? = nil
    
    var changeNumber: Int64 = 0
    
    var updateTimestamp: Int64 = 0
    
    var splitsFilterQueryString: String = ""
    
    var clearCalled = false
    
    func loadLocal() {
        
    }
    
    func get(name: String) -> Split? {
        return nil
    }
    
    func getMany(splits: [String]) -> [String : Split] {
        return [:]
    }
    
    func getAll() -> [String : Split] {
        return [:]
    }
    
    func update(splitChange: ProcessedSplitChange) {
        self.updatedSplitChange = splitChange
    }
    
    func update(filterQueryString: String) {
        self.splitsFilterQueryString = filterQueryString
    }
    
    func updateWithoutChecks(split: Split) {
        
    }
    
    func isValidTrafficType(name: String) -> Bool {
        return true
    }
    
    func clear() {
        clearCalled = true
    }
}
