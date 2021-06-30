//
//  ImpressionsCountDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 30-06-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionsCountDaoTests: XCTestCase {

    var countDao: ImpressionsCountDao!

    override func setUp() {
        let queue = DispatchQueue(label: "count dao test")
        countDao = CoreDataImpressionsCountDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        let counts = createImpressionsCounts()
        for count in counts {
            countDao.insert(count)
        }

    }

    func testInsertGet() {

        let loadedImpressionsCounts = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedImpressionsCounts.count)
    }

    func testUpdate() {

        let loadedImpressionsCounts = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        countDao.update(ids: loadedImpressionsCounts.prefix(5).compactMap { return $0.storageId }, newStatus: StorageRecordStatus.deleted)
        let active = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = countDao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    /// TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        countDao.delete(Array(toDelete))
        let loadedImpressionsCounts = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedImpressionsCounts.count)
        XCTAssertEqual(0, loadedImpressionsCounts.filter { notFound.contains($0.storageId)}.count)
    }

    func testLoadOutdated() {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedImpressionsCounts = countDao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedImpressionsCounts1 = countDao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedImpressionsCounts.count)
        XCTAssertEqual(0, loadedImpressionsCounts1.count)
    }

    override func tearDown() {

    }

    func createImpressionsCounts() -> [ImpressionsCountPerFeature] {
        var counts = [ImpressionsCountPerFeature]()
        for _ in 0..<10 {
            let count = ImpressionsCountPerFeature(feature: "name", timeframe: 1000, count: 1)
            counts.append(count)
        }
        return counts
    }
}
