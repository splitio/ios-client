//
//  DbCipherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class DbCipherTest: XCTestCase {

    let userKey = IntegrationHelper.dummyUserKey
    var dbHelper: CoreDataHelper!
    var db: SplitDatabase!

    override func setUp() {
        dbHelper = createDbHelper()
        db = TestingHelper.createTestDatabase(name: "test",
                                              queue: DispatchQueue.global(),
                                              helper: dbHelper)
    }

    func testEncryptDecryptDb() throws {
        let dbCipherEnc = try createCipher(fromLevel: .none, toLevel: .aes128Cbc, dbHelper: dbHelper)
        let dbCipherDec = try createCipher(fromLevel: .aes128Cbc, toLevel: .none, dbHelper: dbHelper)
        dbHelper.performAndWait {
            insertData(dbHelper: dbHelper)
        }
        Thread.sleep(forTimeInterval: 10)

        dbCipherEnc.apply()

        let resultBefore = loadData(dbHelper: dbHelper)

        dbCipherDec.apply()

        let resultAfter = loadData(dbHelper: dbHelper)

        // Encrypted data
        // Splits
        XCTAssertEqual("=", resultBefore.splits.body.suffix(1))
        XCTAssertEqual("=", resultBefore.splits.name.suffix(1))
        // Segments
        XCTAssertEqual("=", resultBefore.segments.segments.suffix(1))
        XCTAssertEqual("=", resultBefore.segments.userKey.suffix(1))
        // Impressions
        XCTAssertEqual("cRer7", resultBefore.impressions.body.suffix(5))
        XCTAssertEqual("=", resultBefore.impressions.testName.suffix(1))
        // Events
        XCTAssertEqual("=", resultBefore.events.suffix(1))
        // Impressions Count
        XCTAssertEqual("=", resultBefore.impressionsCount.suffix(1))
        // Unique Keys
        XCTAssertEqual("=", resultBefore.uniqueKeys.userKey.suffix(1))
        XCTAssertEqual("FlQ==", resultBefore.uniqueKeys.features.suffix(5))
        // Attributes
        XCTAssertEqual("=", resultBefore.attributes.userKey.suffix(1))
        XCTAssertEqual("=", resultBefore.attributes.attributes.suffix(1))

        // Decrypted data
        // Splits
        XCTAssertEqual("feat_9",resultAfter.splits.name)
        XCTAssertEqual("}",resultAfter.splits.body.suffix(1))
        // Segments
        XCTAssertEqual("s1",resultAfter.segments.segments)
        XCTAssertEqual("CUSTOMER_ID",resultAfter.segments.userKey)
        // Impressions
        XCTAssertEqual("}",resultAfter.impressions.body.suffix(1))
        XCTAssertEqual("split",resultAfter.impressions.testName)
        // Events
        XCTAssertEqual("}",resultAfter.events.suffix(1))
        // Impressions Count
        XCTAssertEqual("}",resultAfter.impressionsCount.suffix(1))
        // Unique Keys
        XCTAssertEqual(IntegrationHelper.dummyUserKey,resultAfter.uniqueKeys.userKey)
        XCTAssertEqual("]",resultAfter.uniqueKeys.features.suffix(1))
        // Attributes
        XCTAssertEqual(IntegrationHelper.dummyUserKey,resultAfter.attributes.userKey)
        XCTAssertEqual("}",resultAfter.attributes.attributes.suffix(1))
    }

    struct DataResult {
        let splits: (name: String, body: String)
        let segments: (userKey: String, segments: String)
        let impressions: (testName: String, body: String)
        let events: String
        let impressionsCount: String
        let uniqueKeys: (userKey: String, features: String)
        let attributes: (userKey: String, attributes: String)
    }

    private func loadData(dbHelper: CoreDataHelper) -> DataResult {
        var result: DataResult?
        dbHelper.performAndWait {
            result = DataResult(splits: dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }.map { (name: $0.name, body: $0.body)}[0],
                                segments: dbHelper.fetch(entity: .mySegment).compactMap { $0 as? MySegmentEntity }.map { (userKey: $0.userKey!, segments: $0.segmentList!) }[0],
                                impressions: dbHelper.fetch(entity: .impression).compactMap { $0 as? ImpressionEntity }.map { (testName: $0.testName, body: $0.body) }[0],
                                events: dbHelper.fetch(entity: .event).compactMap { $0 as? EventEntity }.map { $0.body }[0],
                                impressionsCount: dbHelper.fetch(entity: .impressionsCount).compactMap { $0 as? ImpressionsCountEntity }.map { $0.body }[0],
                                uniqueKeys: dbHelper.fetch(entity: .uniqueKey).compactMap { $0 as? UniqueKeyEntity }.map { (userKey: $0.userKey, features: $0.featureList) }[0],
                                attributes: dbHelper.fetch(entity: .attribute).compactMap { $0 as? AttributeEntity }.map { (userKey: $0.userKey!, attributes: $0.attributes!) }[0]
            )
        }
        return result!
    }

    private func insertData(dbHelper: CoreDataHelper) {
        db.splitDao.insertOrUpdate(splits: TestingHelper.createSplits().suffix(1))
        db.mySegmentsDao.update(userKey: userKey, segmentList: ["s1"])
        db.impressionDao.insert(TestingHelper.createKeyImpressions().suffix(1))
        db.eventDao.insert(TestingHelper.createEvents(count: 1, randomId: false).suffix(1))
        db.impressionsCountDao.insert(ImpressionsCountPerFeature(storageId: "id1", feature: "pepe", timeframe: 111111, count: 1) )
        db.uniqueKeyDao.insert(UniqueKey(userKey: IntegrationHelper.dummyUserKey, features: ["split1"]))
        db.attributesDao.update(userKey: userKey, attributes: ["att1": 1])
    }

    private func createDbHelper() -> CoreDataHelper {
        return IntegrationCoreDataHelper.get(databaseName: "test",
                                             dispatchQueue: DispatchQueue.global())
    }

    private func createCipher(fromLevel: SplitEncryptionLevel,
                              toLevel: SplitEncryptionLevel,
                              dbHelper: CoreDataHelper) throws -> DbCipher {
        return try DbCipher(apiKey: IntegrationHelper.dummyApiKey,
                            from: fromLevel,
                            to: toLevel,
                            coreDataHelper: dbHelper)
    }
}

