//
//  SplitDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SplitDaoTests: XCTestCase {
    
    var splitDao: SplitDao!
    
    // TODO: Research delete test in inMemoryDb
    
    override func setUp() {
        let queue = DispatchQueue(label: "split dao test")
        splitDao = CoreDataSplitDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        let splits = createSplits()
        splitDao.insertOrUpdate(splits: splits)
    }
    
    func testGetUpdateSeveral() {
        let splits = splitDao.getAll()
        
        splitDao.insertOrUpdate(splits: [newSplit(name: "feat_0", trafficType: "ttype")])
        let splitsUpd = splitDao.getAll()
        
        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(10, splitsUpd.count)
        XCTAssertEqual(1, splits.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, splitsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }
    
    func testGetUpdate() {
        let splits = splitDao.getAll()
        
        splitDao.insertOrUpdate(split: newSplit(name: "feat_0", trafficType: "ttype"))
        let splitsUpd = splitDao.getAll()
        
        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(10, splitsUpd.count)
        XCTAssertEqual(1, splits.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, splitsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }
    
    private func createSplits() -> [Split] {
        var splits = [Split]()
        for i in 0..<10 {
            let split = Split()
            split.name = "feat_\(i)"
            split.trafficTypeName = "tt_\(i)"
            split.status = .active
            splits.append(split)
        }
        return splits
    }
    
    private func newSplit(name: String, trafficType: String) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = .active
        return split
    }
}
