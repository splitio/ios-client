//
//  PersistentMySegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PersistentMySegmentsStorageTests: XCTestCase {
    
    var mySegmentsStorage: PersistentMySegmentsStorage!
    var mySegmentsDao: MySegmentsDaoStub!
    let dummyKey = "dummyKey"
    let otherKey = "otherKey"
    
    override func setUp() {
        mySegmentsDao = MySegmentsDaoStub()
        mySegmentsStorage =
            DefaultPersistentMySegmentsStorage(database: SplitDatabaseStub(eventDao: EventDaoStub(),
                                                                           impressionDao: ImpressionDaoStub(),
                                                                           impressionsCountDao: ImpressionsCountDaoStub(),
                                                                           generalInfoDao: GeneralInfoDaoStub(),
                                                                           splitDao: SplitDaoStub(),
                                                                           mySegmentsDao: mySegmentsDao,
                                                                           attributesDao: AttributesDaoStub(),
                                                                           uniqueKeyDao: UniqueKeyDaoStub(), 
                                                                           hashedImpressionDao: HashedImpressionDaoMock()))
    }
    
    func  testSet() {
        mySegmentsStorage.set(["se1", "se2", "se3"], forKey: dummyKey)
        
        let segments = mySegmentsDao.getBy(userKey: dummyKey)
        
        XCTAssertEqual(3, segments.count)
        XCTAssertEqual(1, segments.filter { $0 == "se1" }.count)
        XCTAssertEqual(1, segments.filter { $0 == "se2" }.count)
        XCTAssertEqual(1, segments.filter { $0 == "se3" }.count)
    }

    func  testClear() {
        mySegmentsDao.segments[dummyKey] = ["s1", "s2"]
        mySegmentsStorage.set([], forKey: dummyKey)

        let segments = mySegmentsDao.getBy(userKey: dummyKey)

        XCTAssertEqual(0, segments.count)
    }
    
    func testGetSnapshot() {
        mySegmentsDao.segments[dummyKey] = ["s1", "s2"]
        
        let segments = mySegmentsStorage.getSnapshot(forKey: dummyKey)
        
        XCTAssertEqual(2, segments.count)
        XCTAssertEqual(1, segments.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, segments.filter { $0 == "s2" }.count)
    }

    func testSetMultiKey() {
        mySegmentsStorage.set(["se1", "se2", "se3"], forKey: dummyKey)

        let segments = mySegmentsDao.getBy(userKey: otherKey)

        XCTAssertEqual(0, segments.count)
    }

    func testGetSnapshotMultiKey() {
        mySegmentsDao.segments[dummyKey] = ["s1", "s2"]

        let segments = mySegmentsStorage.getSnapshot(forKey: otherKey)

        XCTAssertEqual(0, segments.count)
    }
    
    override func tearDown() {
    }
}

