//
//  ImpressionsStorageTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class PersistentImpressionsStorageTests: XCTestCase {
    var impressionsStorage: PersistentImpressionsStorage!
    var impressionDao: ImpressionDaoStub!

    override func setUp() {
        impressionDao = ImpressionDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.impressionDao = impressionDao
        impressionsStorage = DefaultImpressionsStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider),
            expirationPeriod: 100)
    }

    func testPush() {
        TestingHelper.createKeyImpressions(count: 20).forEach { impression in
            self.impressionsStorage.push(impression: impression)
        }
        XCTAssertEqual(20, impressionDao.insertedImpressions.count)
    }

    func testPushMany() {
        impressionsStorage.push(impressions: TestingHelper.createKeyImpressions(count: 20))
        impressionsStorage.push(impressions: TestingHelper.createKeyImpressions(count: 20))
        impressionsStorage.push(impressions: TestingHelper.createKeyImpressions(count: 20))

        XCTAssertEqual(60, impressionDao.insertedImpressions.count)
    }

    func testPop() {
        impressionDao.getByImpressions = TestingHelper.createKeyImpressions()
        let popped = impressionsStorage.pop(count: 100)

        XCTAssertEqual(impressionDao.getByImpressions.count, popped.count)
        XCTAssertEqual(impressionDao.updatedImpressions.count, popped.count)
        XCTAssertEqual(0, impressionDao.updatedImpressions.values.filter { $0 == StorageRecordStatus.active }.count)
    }

    func testDelete() {
        let impressions = TestingHelper.createKeyImpressions()
        impressionsStorage.delete(impressions)

        XCTAssertEqual(impressionDao.deletedImpressions.count, impressions.count)
    }

    func testSetActive() {
        let impressions = TestingHelper.createKeyImpressions()

        impressionsStorage.setActive(impressions)

        XCTAssertEqual(
            impressions.count,
            impressionDao.updatedImpressions.values.filter { $0 == StorageRecordStatus.active }.count)
        XCTAssertEqual(0, impressionDao.updatedImpressions.values.filter { $0 == StorageRecordStatus.deleted }.count)
    }

    override func tearDown() {}
}
