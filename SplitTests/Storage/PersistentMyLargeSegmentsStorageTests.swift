//
//  PersistentMyLargeSegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PersistentMyLargeSegmentsStorageTests: XCTestCase {
    var myLargeSegmentsStorage: PersistentMySegmentsStorage!
    var myLargeSegmentsDao: MySegmentsDaoStub!
    let dummyKey = "dummyKey"
    let otherKey = "otherKey"

    override func setUp() {
        myLargeSegmentsDao = MySegmentsDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.myLargeSegmentsDao = myLargeSegmentsDao
        myLargeSegmentsStorage =
            DefaultPersistentMyLargeSegmentsStorage(database: SplitDatabaseStub(daoProvider: daoProvider))
    }

    func testSet() {
        let change = change(["se1", "se2", "se3"], 100)
        myLargeSegmentsStorage.set(change, forKey: dummyKey)

        let loadedChange = myLargeSegmentsDao.getBy(userKey: dummyKey)

        let segments = loadedChange?.segments.map { $0.name }
        XCTAssertEqual(100, loadedChange?.changeNumber)
        XCTAssertEqual(3, segments?.count)
        XCTAssertEqual(1, segments?.filter { $0 == "se1" }.count)
        XCTAssertEqual(1, segments?.filter { $0 == "se2" }.count)
        XCTAssertEqual(1, segments?.filter { $0 == "se3" }.count)
    }

    func testClear() {
        myLargeSegmentsDao.segments[dummyKey] = change(["s1", "s2"], 200)
        myLargeSegmentsStorage.set(change([], -1), forKey: dummyKey)

        let change = myLargeSegmentsDao.getBy(userKey: dummyKey)

        XCTAssertEqual(-1, change?.changeNumber)
        XCTAssertEqual(0, change?.segments.count)
    }

    func testGetSnapshot() {
        let change = change(["s1", "s2"], 300)
        myLargeSegmentsDao.segments[dummyKey] = change

        let newChange = myLargeSegmentsStorage.getSnapshot(forKey: dummyKey)
        let segments = newChange?.segments ?? []

        XCTAssertEqual(300, newChange?.changeNumber)
        XCTAssertEqual(2, segments.count)
        XCTAssertEqual(1, segments.filter { $0.name == "s1" }.count)
        XCTAssertEqual(1, segments.filter { $0.name == "s2" }.count)
    }

    func testSetMultiKey() {
        let change = change(["se1", "se2", "se3"], 400)
        myLargeSegmentsStorage.set(change, forKey: dummyKey)

        let newChange = myLargeSegmentsDao.getBy(userKey: otherKey)

        XCTAssertNil(newChange)
    }

    func testGetSnapshotMultiKey() {
        let change = change(["s1", "s2"], 300)
        myLargeSegmentsDao.segments[dummyKey] = change

        let newChange = myLargeSegmentsStorage.getSnapshot(forKey: otherKey)

        XCTAssertNil(newChange)
    }

    func change(_ segments: [String], _ changeNumber: Int64 = -1) -> SegmentChange {
        return SegmentChange(segments: segments, changeNumber: changeNumber)
    }
}
