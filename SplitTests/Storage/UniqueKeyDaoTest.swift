//
//  UniqueKeyDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 19-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class UniqueKeyDaoTest: XCTestCase {
    var uniqueKeyDao: UniqueKeyDao!
    var uniqueKeyDaoAes128Cbc: UniqueKeyDao!
    var helperPlainText: CoreDataHelper!
    var helperAes128Cbc: CoreDataHelper!

    override func setUp() {
        let queue = DispatchQueue(label: "key dao test")
        helperPlainText = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue)

        uniqueKeyDao = CoreDataUniqueKeyDao(coreDataHelper: helperPlainText)

        helperAes128Cbc = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue)
        uniqueKeyDaoAes128Cbc = CoreDataUniqueKeyDao(
            coreDataHelper: helperAes128Cbc,
            cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
        let keys = createUniqueKeys()
        for key in keys {
            uniqueKeyDao.insert(key)
            uniqueKeyDaoAes128Cbc.insert(key)
        }
    }

    func testInsertGetPlainText() {
        insertGet(dao: uniqueKeyDao)
    }

    func testInsertGetAes128Cbc() {
        insertGet(dao: uniqueKeyDaoAes128Cbc)
    }

    func insertGet(dao: UniqueKeyDao) {
        let loadedUniqueKeys = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedUniqueKeys.count)
    }

    func testUpdatePlainText() {
        update(dao: uniqueKeyDao)
    }

    func testUpdateAes128Cbc() {
        update(dao: uniqueKeyDaoAes128Cbc)
    }

    func update(dao: UniqueKeyDao) {
        let loadedUniqueKeys = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        dao.update(
            ids: loadedUniqueKeys.prefix(5).compactMap { $0.storageId },
            newStatus: StorageRecordStatus.deleted,
            incrementSentCount: false)
        let active = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = dao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    func testUpdateAndIncrementCountPlainText() {
        updateAndIncrementCount(dao: uniqueKeyDao, helper: helperPlainText)
    }

    func testUpdateAndIncrementCountAes128Cbc() {
        updateAndIncrementCount(dao: uniqueKeyDaoAes128Cbc, helper: helperAes128Cbc)
    }

    func updateAndIncrementCount(dao: UniqueKeyDao, helper: CoreDataHelper) {
        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        uniqueKeyDao.update(
            ids: loadedUniqueKeys.prefix(5).compactMap { $0.storageId },
            newStatus: StorageRecordStatus.deleted,
            incrementSentCount: true)
        let active = getByCount(status: StorageRecordStatus.active, helper: helper)
        let deleted = getByCount(status: StorageRecordStatus.deleted, helper: helper)

        for count in active {
            XCTAssertEqual(0, count)
        }

        for count in deleted {
            XCTAssertEqual(1, count)
        }
    }

    func testLoadOutdatedPlainText() {
        loadOutdated(dao: uniqueKeyDao)
    }

    func testLoadOutdatedAes128Cbc() {
        loadOutdated(dao: uniqueKeyDaoAes128Cbc)
    }

    func loadOutdated(dao: UniqueKeyDao) {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedUniqueKeys1 = uniqueKeyDao.getBy(
            createdAt: timestamp,
            status: StorageRecordStatus.deleted,
            maxRows: 20)

        XCTAssertEqual(0, loadedUniqueKeys.count)
        XCTAssertEqual(0, loadedUniqueKeys1.count)
    }

    private func getByCount(status: Int32, helper: CoreDataHelper) -> [Int16] {
        var resp = [Int16]()
        helper.performAndWait {
            let predicate = NSPredicate(format: "status == %d", status)
            let entities = helper.fetch(
                entity: .uniqueKey,
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

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "impression dao test"))
        uniqueKeyDao = CoreDataUniqueKeyDao(coreDataHelper: helper)
        uniqueKeyDaoAes128Cbc = CoreDataUniqueKeyDao(
            coreDataHelper: helper,
            cipher: cipher)

        // create impressions and get one encrypted feature name
        let counts = createUniqueKeys()

        // Insert encrypted impressions
        for count in counts {
            uniqueKeyDaoAes128Cbc.insert(count)
        }

        // load impressions and filter them by encrypted feature name
        let values = getBy(coreDataHelper: helper) ?? ("fail", "fail")

        let list = try? Json.decodeFrom(json: values.1, to: [String].self)

        XCTAssertFalse(values.0.contains("key1"))
        XCTAssertFalse(values.1.contains("name"))
        XCTAssertNil(list)
    }

    private func getBy(coreDataHelper: CoreDataHelper) -> (String, String)? {
        var body: (String, String)? = nil
        coreDataHelper.performAndWait {
            let entities = coreDataHelper.fetch(
                entity: .uniqueKey,
                where: nil,
                rowLimit: 1).compactMap { $0 as? UniqueKeyEntity }
            if !entities.isEmpty {
                body = (entities[0].userKey, entities[0].featureList)
            }
        }
        return body
    }

    // TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        uniqueKeyDao.delete(Array(toDelete).map { $0.storageId ?? "nil" })
        let loadedUniqueKeys = uniqueKeyDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedUniqueKeys.count)
        XCTAssertEqual(0, loadedUniqueKeys.filter { notFound.contains($0.storageId) }.count)
    }

    private func createUniqueKeys() -> [UniqueKey] {
        var keys = [UniqueKey]()
        for i in 0 ..< 10 {
            keys.append(UniqueKey(
                storageId: UUID().uuidString,
                userKey: "key\(i)",
                features: ["name"]))
        }
        return keys
    }
}
