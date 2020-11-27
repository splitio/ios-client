//
//  ImpressionsStorageTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class PersistentImpressionsStorageTests: XCTestCase {

    var impressionsStorage: PersistentImpressionsStorage!
    var impressionDao: ImpressionDaoStub!

    override func setUp() {
        impressionDao = ImpressionDaoStub()
        impressionsStorage = DefaultImpressionsStorage(database: SplitDatabaseStub(eventDao: EventDaoStub(),
                                                                                   impressionDao: impressionDao,
                                                                                   generalInfoDao: GeneralInfoDaoStub(),
                                                                                   splitDao: SplitDaoStub()), expirationPeriod: 100)

    }

    func testPush() {
        createImpressions().forEach { impression in
            self.impressionsStorage.push(impression: impression)
        }
        XCTAssertEqual(20, impressionDao.insertedImpressions.count)
    }

    func testPop() {
        impressionDao.getByImpressions = createImpressions()
        let popped = impressionsStorage.pop(count: 100)

        XCTAssertEqual(impressionDao.getByImpressions.count, popped.count)
        XCTAssertEqual(impressionDao.updatedImpressions.count, popped.count)
        XCTAssertEqual(0, impressionDao.updatedImpressions.values.filter { $0 == StorageRecordStatus.active }.count)
    }

    func testDelete() {
        let impressions = createImpressions()
        impressionsStorage.delete(impressions)

        XCTAssertEqual(impressionDao.deletedImpressions.count, impressions.count)
    }

    func testSetActive() {
        let impressions = createImpressions()

        impressionsStorage.setActive(impressions)

        XCTAssertEqual(impressions.count, impressionDao.updatedImpressions.values.filter { $0 ==  StorageRecordStatus.active }.count)
        XCTAssertEqual(0, impressionDao.updatedImpressions.values.filter { $0 ==  StorageRecordStatus.deleted }.count )
    }

    override func tearDown() {
    }

    func createImpressions() -> [Impression] {
        var impressions = [Impression]()
        for _ in 0..<20 {
            let impression = Impression()
            impression.storageId = UUID().uuidString
            impression.feature = "f1"
            impression.keyName = "key1"
            impression.treatment = "t1"
            impression.time = 1000
            impression.changeNumber = 1000
            impression.label = "t1"
            impression.attributes = ["pepe": 1]
            impressions.append(impression)
        }
        return impressions
    }
}
