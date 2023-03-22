//
//  ImpressionDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionDaoTests: XCTestCase {

    var impressionDao: ImpressionDao!

    override func setUp() {
        let queue = DispatchQueue(label: "impression dao test")
        impressionDao = CoreDataImpressionDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue))
        let impressions = createImpressions()
        for impression in impressions {
            impressionDao.insert(impression)
        }

    }

    func testInsertGet() {

        let loadedImpressions = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedImpressions.count)
    }

    func testInsertManyGet() {
        impressionDao.insert(createImpressions())

        let loadedImpressions = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 40)

        XCTAssertEqual(20, loadedImpressions.count)
    }

    func testUpdate() {

        let loadedImpressions = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        impressionDao.update(ids: loadedImpressions.prefix(5).compactMap { return $0.storageId }, newStatus: StorageRecordStatus.deleted)
        let active = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    /// TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        impressionDao.delete(Array(toDelete))
        let loadedImpressions = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedImpressions.count)
        XCTAssertEqual(0, loadedImpressions.filter { notFound.contains($0.storageId)}.count)
    }

    func testLoadOutdated() {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedImpressions = impressionDao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedImpressions1 = impressionDao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedImpressions.count)
        XCTAssertEqual(0, loadedImpressions1.count)
    }

    override func tearDown() {

    }

    func createImpressions() -> [KeyImpression] {
        var impressions = [KeyImpression]()
        for _ in 0..<10 {
            let impression = KeyImpression(featureName: "f1",
                                           keyName: "key1",
                                           bucketingKey: nil,
                                           treatment: "t1",
                                           label: "t1",
                                           time: 1000,
                                           changeNumber: 1000,
                                           previousTime: nil,
                                           storageId: nil)
            impressions.append(impression)
        }
        return impressions
    }
}
