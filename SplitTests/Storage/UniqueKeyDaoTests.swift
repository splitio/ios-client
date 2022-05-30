//
//  UniqueKeyDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 19-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class UniqueKeyDaoTests: XCTestCase {

    var uniqueKeyDao: UniqueKeyDao!
    var helper: CoreDataHelper!

    override func setUp() {
        let queue = DispatchQueue(label: "key dao test")
        helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                                 dispatchQueue: queue)
        uniqueKeyDao = CoreDataUniqueKeyDao(coreDataHelper: helper)
        let keys = createUniqueKeys()
        for key in keys {
            uniqueKeyDao.insert(key)
        }

    }

    func testInsertGet() {

        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedUniqueKeys.count)
    }

    func testUpdate() {

        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        uniqueKeyDao.update(ids: loadedUniqueKeys.prefix(5).compactMap { return $0.storageId },
                            newStatus: StorageRecordStatus.deleted,
        incrementSentCount: false)
        let active = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    func testUpdateAndIncrementCount() {

        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        uniqueKeyDao.update(ids: loadedUniqueKeys.prefix(5).compactMap { return $0.storageId },
                            newStatus: StorageRecordStatus.deleted,
        incrementSentCount: true)
        let active = getByCount(status: StorageRecordStatus.active)
        let deleted = getByCount(status: StorageRecordStatus.deleted)


        for count in active {
            XCTAssertEqual(0, count)
        }

        for count in deleted {
            XCTAssertEqual(1, count)
        }
    }

    /// TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        uniqueKeyDao.delete(Array(toDelete).map { $0.storageId ?? "nil"})
        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedUniqueKeys.count)
        XCTAssertEqual(0, loadedUniqueKeys.filter { notFound.contains($0.storageId)}.count)
    }

    func testLoadOutdated() {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedUniqueKeys1 = uniqueKeyDao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedUniqueKeys.count)
        XCTAssertEqual(0, loadedUniqueKeys1.count)
    }


    private func getByCount(status: Int32) -> [Int16] {
        var resp = [Int16]()
        helper.performAndWait {
            let predicate = NSPredicate(format: "status == %d", status)
            let entities = helper.fetch(entity: .uniqueKey,
                                        where: predicate,
                                        rowLimit: 100)


            entities.forEach {
                if let entity = $0 as? UniqueKeyEntity {
                    resp.append(entity.sendAttemptCount)
                }
            }
        }
        return resp
    }

    override func tearDown() {

    }

    func createUniqueKeys() -> [UniqueKey] {
        var keys = [UniqueKey]()
        for i in 0..<10 {
            keys.append(UniqueKey(storageId: UUID().uuidString,
                                  userKey: "key\(i)",
                                  features: ["name"]))
        }
        return keys
    }
}
