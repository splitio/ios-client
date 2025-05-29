//
//  ImpressionsCountsStorageTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class PersistentImpressionsCountStorageTests: XCTestCase {
    var countsStorage: PersistentImpressionsCountStorage!
    var countDao: ImpressionsCountDaoStub!

    override func setUp() {
        countDao = ImpressionsCountDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.impressionsCountDao = countDao
        countsStorage = DefaultImpressionsCountStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider),
            expirationPeriod: 100)
    }

    func testPush() {
        countsStorage.pushMany(counts: createImpressionsCounts())

        XCTAssertEqual(20, countDao.insertedCounts.count)
    }

    func testPop() {
        countDao.getByCounts = createImpressionsCounts()
        let popped = countsStorage.pop(count: 100)

        XCTAssertEqual(countDao.getByCounts.count, popped.count)
        XCTAssertEqual(countDao.updatedCounts.count, popped.count)
        XCTAssertEqual(0, countDao.updatedCounts.values.filter { $0 == StorageRecordStatus.active }.count)
    }

    func testDelete() {
        let counts = createImpressionsCounts()
        countsStorage.delete(counts)

        XCTAssertEqual(countDao.deletedCounts.count, counts.count)
    }

    func testSetActive() {
        let counts = createImpressionsCounts()

        countsStorage.setActive(counts)

        XCTAssertEqual(counts.count, countDao.updatedCounts.values.filter { $0 == StorageRecordStatus.active }.count)
        XCTAssertEqual(0, countDao.updatedCounts.values.filter { $0 == StorageRecordStatus.deleted }.count)
    }

    override func tearDown() {}

    func createImpressionsCounts() -> [ImpressionsCountPerFeature] {
        var counts = [ImpressionsCountPerFeature]()
        for _ in 0 ..< 20 {
            let count = ImpressionsCountPerFeature(
                storageId: UUID().uuidString,
                feature: "f1",
                timeframe: 1000,
                count: 1)
            counts.append(count)
        }
        return counts
    }
}
