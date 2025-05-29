//
//  ImpressionDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionDaoTest: XCTestCase {
    var impressionDao: ImpressionDao!
    var impressionDaoAes128Cbc: ImpressionDao!

    override func setUp() {
        let queue = DispatchQueue(label: "impression dao test")
        impressionDao = CoreDataImpressionDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
        impressionDaoAes128Cbc = CoreDataImpressionDao(
            coreDataHelper: IntegrationCoreDataHelper.get(
                databaseName: "test",
                dispatchQueue: queue),
            cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))

        let impressions = createImpressions()
        for impression in impressions {
            impressionDao.insert(impression)
            impressionDaoAes128Cbc.insert(impression)
        }
    }

    func testInsertGet() {
        insertGet(dao: impressionDao)
    }

    func testInsertGetAes128Cbc() {
        insertGet(dao: impressionDaoAes128Cbc)
    }

    private func insertGet(dao: ImpressionDao) {
        let loadedImpressions = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedImpressions.count)
    }

    func testInsertManyGet() {
        insertManyGet(dao: impressionDao)
    }

    func testInsertManyGetAes128Cbc() {
        insertManyGet(dao: impressionDaoAes128Cbc)
    }

    private func insertManyGet(dao: ImpressionDao) {
        dao.insert(createImpressions())

        let loadedImpressions = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 40)

        XCTAssertEqual(20, loadedImpressions.count)
    }

    func testUpdate() {
        update(dao: impressionDao)
    }

    func testUpdateAes128Cbc() {
        update(dao: impressionDaoAes128Cbc)
    }

    private func update(dao: ImpressionDao) {
        let loadedImpressions = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        dao.update(ids: loadedImpressions.prefix(5).compactMap { $0.storageId }, newStatus: StorageRecordStatus.deleted)
        let active = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = dao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    func testLoadOutdated() {
        loadOutdated(dao: impressionDao)
    }

    func testLoadOutdatedAes128Cbc() {
        loadOutdated(dao: impressionDaoAes128Cbc)
    }

    private func loadOutdated(dao: ImpressionDao) {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedImpressions = impressionDao.getBy(
            createdAt: timestamp,
            status: StorageRecordStatus.active,
            maxRows: 20)
        let loadedImpressions1 = impressionDao.getBy(
            createdAt: timestamp,
            status: StorageRecordStatus.deleted,
            maxRows: 20)

        XCTAssertEqual(0, loadedImpressions.count)
        XCTAssertEqual(0, loadedImpressions1.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "impression dao test"))
        impressionDao = CoreDataImpressionDao(coreDataHelper: helper)
        impressionDaoAes128Cbc = CoreDataImpressionDao(
            coreDataHelper: helper,
            cipher: cipher)

        // create impressions and get one encrypted feature name
        let impressions = createImpressions()
        let testNameEnc = cipher.encrypt(impressions[0].featureName) ?? "fail"

        // Insert encrypted impressions
        for impression in impressions {
            impressionDaoAes128Cbc.insert(impression)
        }

        // load impressions and filter them by encrypted feature name
        let loadedImpression = getBy(testName: testNameEnc, coreDataHelper: helper)

        let impression = try? Json.decodeFrom(json: loadedImpression ?? "", to: KeyImpression.self)

        XCTAssertNotNil(loadedImpression)
        XCTAssertFalse(loadedImpression?.contains("key1") ?? true)
        XCTAssertNil(impression)
    }

    func getBy(testName: String, coreDataHelper: CoreDataHelper) -> String? {
        var body: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "testName == %@", testName)
            let entities = coreDataHelper.fetch(
                entity: .impression,
                where: predicate,
                rowLimit: 1).compactMap { $0 as? ImpressionEntity }
            if !entities.isEmpty {
                body = entities[0].body
            }
        }
        return body
    }

    // TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        impressionDao.delete(Array(toDelete))
        let loadedImpressions = impressionDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedImpressions.count)
        XCTAssertEqual(0, loadedImpressions.filter { notFound.contains($0.storageId) }.count)
    }

    func createImpressions() -> [KeyImpression] {
        var impressions = [KeyImpression]()
        for _ in 0 ..< 10 {
            let impression = KeyImpression(
                featureName: "f1",
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
