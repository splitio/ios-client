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
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.splitDao = splitDao
        daoProvider.generalInfoDao = generalInfoDao
        splitsStorage = DefaultPersistentSplitsStorage(database: SplitDatabaseStub(daoProvider: daoProvider))
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

    func testUpdateBySetFilter() {
        splitsStorage.update(bySetsFilter: SplitFilter(type: .bySet, values: ["set1", "set2"]))

        let filter = try? Json.decodeFrom(json: generalInfoDao.stringValue(info: .bySetsFilter) ?? "", to: SplitFilter.self)

        XCTAssertEqual(SplitFilter.FilterType.bySet, filter?.type)
        XCTAssertEqual(["set1", "set2"], filter?.values.sorted())
    }

    func testGetBySetFilter() {
        generalInfoDao.update(info: .bySetsFilter, stringValue: "{\"values\":[\"set1\",\"set2\"],\"type\":0}")

        let filter = splitsStorage.getBySetsFilter()

        XCTAssertEqual(SplitFilter.FilterType.bySet, filter?.type)
        XCTAssertEqual(["set1", "set2"], filter?.values.sorted())
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
    
    private func createSplits() -> [Split] {
        return SplitTestHelper.createSplits(namePrefix: "feat_", count: 10)
    }
    
    private func newSplit(name: String, trafficType: String, status: Status = .active) -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: trafficType)
        split.status = status
        return split
    }
}

