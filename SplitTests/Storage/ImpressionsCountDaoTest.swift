//
//  ImpressionsCountDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 30-06-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsCountDaoTest: XCTestCase {
    var countDao: ImpressionsCountDao!
    var countDaoAes128Cbc: ImpressionsCountDao!

    override func setUp() {
        let queue = DispatchQueue(label: "count dao test")
        countDao = CoreDataImpressionsCountDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
        countDaoAes128Cbc = CoreDataImpressionsCountDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))
        let counts = createImpressionsCounts()
        for count in counts {
            countDao.insert(count)
            countDaoAes128Cbc.insert(count)
        }
    }

    func testInsertGetPlainText() {
        insertGet(dao: countDao)
    }

    func testInsertGetAes128Cbc() {
        insertGet(dao: countDaoAes128Cbc)
    }

    func insertGet(dao: ImpressionsCountDao) {
        let loadedImpressionsCounts = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedImpressionsCounts.count)
    }

    func testUpdatePlainText() {
        update(dao: countDao)
    }

    func testUpdateGetAes128Cbc() {
        update(dao: countDaoAes128Cbc)
    }

    func update(dao: ImpressionsCountDao) {
        let loadedImpressionsCounts = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        dao.update(
            ids: loadedImpressionsCounts.prefix(5).compactMap { $0.storageId },
            newStatus: StorageRecordStatus.deleted)
        let active = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = dao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    func testLoadOutdatedPlainText() {
        loadOutdated(dao: countDao)
    }

    func testLoadOutdatedGetAes128Cbc() {
        loadOutdated(dao: countDaoAes128Cbc)
    }

    func loadOutdated(dao: ImpressionsCountDao) {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedImpressionsCounts = dao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedImpressionsCounts1 = dao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedImpressionsCounts.count)
        XCTAssertEqual(0, loadedImpressionsCounts1.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "impression dao test"))
        countDao = CoreDataImpressionsCountDao(coreDataHelper: helper)
        countDaoAes128Cbc = CoreDataImpressionsCountDao(
            coreDataHelper: helper,
            cipher: cipher)

        // create impressions and get one encrypted feature name
        let counts = createImpressionsCounts()

        // Insert encrypted impressions
        for count in counts {
            countDaoAes128Cbc.insert(count)
        }

        // load impressions and filter them by encrypted feature name
        let loadedCountBody = getBy(coreDataHelper: helper)

        let count = try? Json.decodeFrom(json: loadedCountBody ?? "", to: ImpressionsCountPerFeature.self)

        XCTAssertNotNil(loadedCountBody)
        XCTAssertNotEqual("}", loadedCountBody?.suffix(1) ?? "")
        XCTAssertNil(count)
    }

    func getBy(coreDataHelper: CoreDataHelper) -> String? {
        var body: String? = nil
        coreDataHelper.performAndWait {
            let entities = coreDataHelper.fetch(
                entity: .impressionsCount,
                where: nil,
                rowLimit: 1).compactMap { $0 as? ImpressionsCountEntity }
            if !entities.isEmpty {
                body = entities[0].body
            }
        }
        return body
    }

    // TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        countDao.delete(Array(toDelete))
        let loadedImpressionsCounts = countDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedImpressionsCounts.count)
        XCTAssertEqual(0, loadedImpressionsCounts.filter { notFound.contains($0.storageId) }.count)
    }

    func createImpressionsCounts() -> [ImpressionsCountPerFeature] {
        var counts = [ImpressionsCountPerFeature]()
        for _ in 0 ..< 10 {
            let count = ImpressionsCountPerFeature(
                storageId: UUID().uuidString,
                feature: "name",
                timeframe: 1000,
                count: 1)
            counts.append(count)
        }
        return counts
    }
}
