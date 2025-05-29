//
//  SplitDaoTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SplitDaoTest: XCTestCase {
    var splitDao: SplitDao!
    var splitDaoAes128Cbc: SplitDao!

    // TODO: Research delete test in inMemoryDb

    override func setUp() {
        let cipherKey = IntegrationHelper.dummyCipherKey
        let queue = DispatchQueue(label: "split dao test")
        splitDao = CoreDataSplitDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))

        splitDaoAes128Cbc = CoreDataSplitDao(
            coreDataHelper: IntegrationCoreDataHelper.get(
                databaseName: "test",
                dispatchQueue: queue),
            cipher: DefaultCipher(cipherKey: cipherKey))
        let splits = createSplits()
        splitDao.insertOrUpdate(splits: splits)
        splitDaoAes128Cbc.insertOrUpdate(splits: splits)
    }

    func testGetUpdateSeveralPlainText() {
        getUpdateSeveral(dao: splitDao)
    }

    func testGetUpdateSeveralAes128Cbc() {
        getUpdateSeveral(dao: splitDaoAes128Cbc)
    }

    func getUpdateSeveral(dao: SplitDao) {
        let splits = dao.getAll()

        dao.insertOrUpdate(splits: [newSplit(name: "feat_0", trafficType: "ttype")])
        let splitsUpd = dao.getAll()

        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(10, splitsUpd.count)
        XCTAssertEqual(1, splits.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, splitsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }

    func testGetUpdate() {
        getUpdate(dao: splitDao)
    }

    func testGetUpdateAes128Cbc() {
        getUpdate(dao: splitDaoAes128Cbc)
    }

    func getUpdate(dao: SplitDao) {
        let splits = dao.getAll()

        dao.insertOrUpdate(split: newSplit(name: "feat_0", trafficType: "ttype"))
        let splitsUpd = dao.getAll()

        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(10, splitsUpd.count)
        XCTAssertEqual(1, splits.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, splitsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }

    func testDeleteAllPlainText() {
        deleteAll(dao: splitDao)
    }

    func testDeleteAllAes128Cbc() {
        deleteAll(dao: splitDaoAes128Cbc)
    }

    func deleteAll(dao: SplitDao) {
        let splitsBefore = dao.getAll()
        dao.deleteAll()
        let splitsAfter = dao.getAll()

        XCTAssertEqual(10, splitsBefore.count)
        XCTAssertEqual(0, splitsAfter.count)
    }

    func testCreateGetPlainText() {
        createGet(dao: splitDao)
    }

    func testCreateGetAes128Cbc() {
        createGet(dao: splitDaoAes128Cbc)
    }

    func createGet(dao: SplitDao) {
        let splits = dao.getAll()

        dao.insertOrUpdate(split: newSplit(name: "feat_100", trafficType: "ttype"))
        let splitsUpd = dao.getAll()

        XCTAssertEqual(10, splits.count)
        XCTAssertEqual(11, splitsUpd.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "split dao test"))
        splitDao = CoreDataSplitDao(coreDataHelper: helper)
        splitDaoAes128Cbc = CoreDataSplitDao(
            coreDataHelper: helper,
            cipher: cipher)

        // create impressions and get one encrypted feature name
        let splits = createSplits()
        let testNameEnc = cipher.encrypt(splits[0].name) ?? "fail"

        // Insert encrypted impressions
        for split in splits {
            splitDaoAes128Cbc.insertOrUpdate(split: split)
        }

        // load impressions and filter them by encrypted feature name
        let loadSplit = getBy(testName: testNameEnc, coreDataHelper: helper)

        let split = try? Json.decodeFrom(json: loadSplit.body ?? "", to: Split.self)

        XCTAssertNotNil(loadSplit)
        XCTAssertFalse(loadSplit.name?.contains("feat_") ?? true)
        XCTAssertFalse(loadSplit.body?.contains("tt_") ?? true)
        XCTAssertNil(split)
    }

    func getBy(testName: String, coreDataHelper: CoreDataHelper) -> (name: String?, body: String?) {
        var name: String? = nil
        var body: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "name == %@", testName)
            let entities = coreDataHelper.fetch(
                entity: .split,
                where: predicate,
                rowLimit: 1).compactMap { $0 as? SplitEntity }
            if !entities.isEmpty {
                name = entities[0].name
                body = entities[0].body
            }
        }
        return (name: name, body: body)
    }

    private func createSplits() -> [Split] {
        return SplitTestHelper.createSplits(namePrefix: "feat_", count: 10)
    }

    private func newSplit(name: String, trafficType: String) -> Split {
        return SplitTestHelper.newSplit(name: name, trafficType: trafficType)
    }
}
