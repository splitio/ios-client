//
//  PersistentMySegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PersistentMySegmentsStorageTests: XCTestCase {
    var mySegmentsStorage: PersistentMySegmentsStorage!
    var mySegmentsDao: MySegmentsDaoStub!
    let dummyKey = "dummyKey"
    let otherKey = "otherKey"

    override func setUp() {
        mySegmentsDao = MySegmentsDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.mySegmentsDao = mySegmentsDao
        mySegmentsStorage =
            DefaultPersistentMySegmentsStorage(database: SplitDatabaseStub(daoProvider: daoProvider))
    }

    func testSet() {
        let change = SegmentChange(segments: ["se1", "se2", "se3"])
        mySegmentsStorage.set(change, forKey: dummyKey)

        let segments = mySegmentsDao.getBy(userKey: dummyKey)?.segments.map { $0.name } ?? []

        XCTAssertEqual(3, segments.count)
        XCTAssertEqual(1, segments.filter { $0 == "se1" }.count)
        XCTAssertEqual(1, segments.filter { $0 == "se2" }.count)
        XCTAssertEqual(1, segments.filter { $0 == "se3" }.count)
    }

    func testClear() {
        mySegmentsDao.segments[dummyKey] = SegmentChange(segments: ["s1", "s2"])
        mySegmentsStorage.set(SegmentChange(segments: []), forKey: dummyKey)

        let segments = mySegmentsDao.getBy(userKey: dummyKey)?.segments ?? []

        XCTAssertEqual(0, segments.count)
    }

    func testGetSnapshot() {
        mySegmentsDao.segments[dummyKey] = SegmentChange(segments: ["s1", "s2"])

        let segments = mySegmentsStorage.getSnapshot(forKey: dummyKey)

        XCTAssertEqual(2, segments?.segments.count)
        XCTAssertEqual(1, segments?.segments.filter { $0.name == "s1" }.count)
        XCTAssertEqual(1, segments?.segments.filter { $0.name == "s2" }.count)
    }

    func testSetMultiKey() {
        let change = SegmentChange(segments: ["se1", "se2", "se3"])
        mySegmentsStorage.set(change, forKey: dummyKey)

        let segments = mySegmentsDao.getBy(userKey: otherKey)?.segments ?? []

        XCTAssertEqual(0, segments.count)
    }

    func testGetSnapshotMultiKey() {
        mySegmentsDao.segments[dummyKey] = SegmentChange(segments: ["s1", "s2"])

        let segments = mySegmentsStorage.getSnapshot(forKey: otherKey)

        XCTAssertNil(segments?.segments.count)
    }

    func testDeleteAllCallsDeleteAllOnDao() {
        let initialDeleteAllCalled = mySegmentsDao.deleteAllCalled
        mySegmentsStorage.deleteAll()
        let finalDeleteAllCalled = mySegmentsDao.deleteAllCalled
        XCTAssertFalse(initialDeleteAllCalled)
        XCTAssertTrue(finalDeleteAllCalled)
    }
}
