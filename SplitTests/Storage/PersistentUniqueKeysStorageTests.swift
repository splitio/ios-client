//
//  PersistentUniqueKeysStorageTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17-May-2022
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PersistentUniqueKeysStorageTests: XCTestCase {
    
    var uniqueKeysStorage: PersistentUniqueKeysStorage!
    var uniqueKeysDao: UniqueKeyDaoStub!
    let dummyKey = "dummyKey"
    let otherKey = "otherKey"
    
    override func setUp() {
        uniqueKeysDao = UniqueKeyDaoStub()
        uniqueKeysStorage =
            DefaultPersistentUniqueKeysStorage(database: SplitDatabaseStub(eventDao: EventDaoStub(),
                                                                           impressionDao: ImpressionDaoStub(),
                                                                           impressionsCountDao: ImpressionsCountDaoStub(),
                                                                           generalInfoDao: GeneralInfoDaoStub(),
                                                                           splitDao: SplitDaoStub(),
                                                                           mySegmentsDao: MySegmentsDaoStub(),
                                                                           attributesDao: AttributesDaoStub(),
                                                                           uniqueKeyDao: uniqueKeysDao))
    }
    
    func  testSet() {
        uniqueKeysStorage.set(["se1", "se2", "se3"], forKey: dummyKey)
        
        let features = uniqueKeysDao.getBy(userKey: dummyKey)
        
        XCTAssertEqual(3, features.count)
        XCTAssertEqual(1, features.filter { $0 == "se1" }.count)
        XCTAssertEqual(1, features.filter { $0 == "se2" }.count)
        XCTAssertEqual(1, features.filter { $0 == "se3" }.count)
    }

    func  testClear() {
        uniqueKeysDao.features[dummyKey] = ["s1", "s2"]
        uniqueKeysStorage.set([], forKey: dummyKey)

        let features = uniqueKeysDao.getBy(userKey: dummyKey)

        XCTAssertEqual(0, features.count)
    }
    
    func testGetSnapshot() {
        uniqueKeysDao.features[dummyKey] = ["s1", "s2"]
        
        let features = uniqueKeysStorage.getSnapshot(forKey: dummyKey)
        
        XCTAssertEqual(2, features.count)
        XCTAssertEqual(1, features.filter { $0 == "s1" }.count)
        XCTAssertEqual(1, features.filter { $0 == "s2" }.count)
    }

    func testSetMultiKey() {
        uniqueKeysStorage.set(["se1", "se2", "se3"], forKey: dummyKey)

        let features = uniqueKeysDao.getBy(userKey: otherKey)

        XCTAssertEqual(0, features.count)
    }

    func testGetSnapshotMultiKey() {
        uniqueKeysDao.features[dummyKey] = ["s1", "s2"]

        let features = uniqueKeysStorage.getSnapshot(forKey: otherKey)

        XCTAssertEqual(0, features.count)
    }
    
    override func tearDown() {
    }
}

