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

class SplitDaoTest: XCTestCase {
    
    var splitDao: SplitDao!
    var splitDaoAes128Cbc: SplitDao!
    
    // TODO: Research delete test in inMemoryDb
    
    override func setUp() {
        let cipherKey = String(UUID().uuidString.prefix(16))
        let queue = DispatchQueue(label: "split dao test")
        splitDao = CoreDataSplitDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))

        splitDaoAes128Cbc = CoreDataSplitDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
                                       cipher: DefaultCipher(key: cipherKey))
        let splits = createSplits()
        splitDao.insertOrUpdate(splits: splits)
        splitDaoAes128Cbc.insertOrUpdate(splits: splits)
    }
    
    func testGetUpdateSeveralPlainText() {
        getUpdateSeveral(dao: splitDao)
    }

    func testGetUpdateSeveralAes128Cbc() {
        getUpdateSeveral(dao: splitDaoAes128Cbc)
    }

    func getUpdateSeveral(dao: SplitDao) {
        let splits = dao.getAll()
        
        dao.insertOrUpdate(splits: [newSplit(name: "feat_0", trafficType: "ttype")])
        let splitsUpd = dao.getAll()
        
        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(10, splitsUpd.count)
        XCTAssertEqual(1, splits.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, splitsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }

    func testGetUpdate() {
        getUpdate(dao: splitDao)
    }

    func testGetUpdateAes128Cbc() {
        getUpdate(dao: splitDaoAes128Cbc)
    }

    func getUpdate(dao: SplitDao) {
        let splits = dao.getAll()
        
        dao.insertOrUpdate(split: newSplit(name: "feat_0", trafficType: "ttype"))
        let splitsUpd = dao.getAll()
        
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
