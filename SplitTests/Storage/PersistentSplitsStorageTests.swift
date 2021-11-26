//
//  PersistentSplitsStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PersistentSplitsStorageTest: XCTestCase {
    
    var splitsStorage: PersistentSplitsStorage!
    var splitDao: SplitDaoStub!
    var generalInfoDao: GeneralInfoDao!

    override func setUp() {
        splitDao = SplitDaoStub()
        generalInfoDao = GeneralInfoDaoStub()
        splitsStorage = DefaultPersistentSplitsStorage(database: SplitDatabaseStub(eventDao: EventDaoStub(),
                                                                                   impressionDao: ImpressionDaoStub(),
                                                                                   impressionsCountDao: ImpressionsCountDaoStub(),
                                                                                   generalInfoDao: generalInfoDao,
                                                                                   splitDao: splitDao,
                                                                                   mySegmentsDao: MySegmentsDaoStub(),
                                                                                   attributesDao: AttributesDaoStub()))

    }
    
    func testUpdateProcessedChange() {
        let activeSplits = [newSplit(name: "ac1", trafficType: "t1"), newSplit(name: "ac2", trafficType: "t1"), newSplit(name: "ac3", trafficType: "t1")]
        let archivedSplits = [newSplit(name: "ar1", trafficType: "t2", status: .archived), newSplit(name: "ar2", trafficType: "t2", status: .archived)]
        let change = ProcessedSplitChange(activeSplits: activeSplits, archivedSplits: archivedSplits, changeNumber: 100, updateTimestamp: 200)
        
        splitsStorage.update(splitChange: change)
        
        XCTAssertEqual(3, splitDao.insertedSplits.count)
        XCTAssertEqual(2, splitDao.deletedSplits?.count)
        XCTAssertEqual(100, generalInfoDao.longValue(info: .splitsChangeNumber))
        XCTAssertEqual(200, generalInfoDao.longValue(info: .splitsUpdateTimestamp))
    }
    
    func testUpdateSplit() {
        let split = newSplit(name: "s1", trafficType: "t1")
        
        splitsStorage.update(split: split)
        
        XCTAssertEqual(1, splitDao.insertedSplits.count)
        XCTAssertEqual("s1", splitDao.insertedSplits[0].name)
    }
    
    func testGetSplitsQueryString() {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "qs")
        
        let qs = splitsStorage.getFilterQueryString()
        
        XCTAssertEqual("qs", qs)
    }
    
    func testDelete() {

        splitsStorage.delete(splitNames: ["s1", "s2"])
        
        XCTAssertEqual(2, splitDao.deletedSplits?.count)
        XCTAssertEqual(1, splitDao.deletedSplits?.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, splitDao.deletedSplits?.filter { $0 == "s2" }.count)
    }
    
    func testClear() {

        splitsStorage.clear()
        
        XCTAssertTrue(splitDao.deleteAllCalled)
    }

    
    override func tearDown() {
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
    
    private func newSplit(name: String, trafficType: String, status: Status = .active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
}


//func update(splitChange: ProcessedSplitChange)
//func update(split: Split)
//func getFilterQueryString() -> String
//func getSplitsSnapshot() -> SplitsSnapshot
//func getAll() -> [Split]
//func delete(splitNames: [String])
//func clear()
//func close()

