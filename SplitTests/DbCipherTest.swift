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
        XCTAssertFalse(resultBefore.splits.body.contains("name"))
        XCTAssertFalse(resultBefore.splits.name.contains("feat"))
        // Segments
        XCTAssertFalse(resultBefore.segments.segments.contains("s1"))
        XCTAssertNotEqual(userKey, resultBefore.segments.userKey)
        // Impressions
        XCTAssertFalse(resultBefore.impressions.body.contains("key1"))
        XCTAssertNotEqual("split", resultBefore.impressions.testName)
        // Events
        XCTAssertFalse(resultBefore.events.contains("key1"))
        // Impressions
        XCTAssertFalse(resultBefore.impressionsCount.contains("pepe"))
        // Unique Keys
        XCTAssertNotEqual(userKey, resultBefore.uniqueKeys.userKey)
        XCTAssertFalse(resultBefore.uniqueKeys.features.contains("split1"))
        // Attributes
        XCTAssertNotEqual(userKey, resultBefore.attributes.userKey)
        XCTAssertFalse(resultBefore.attributes.attributes.contains("att1"))
        // RBS
        XCTAssertNotEqual("test_rbs", resultBefore.ruleBasedSegments.name)
        XCTAssertFalse(resultBefore.ruleBasedSegments.body.contains("test_rbs"))

        // Decrypted data
        // Splits
        XCTAssertTrue(resultAfter.splits.body.contains("name"))
        XCTAssertTrue(resultAfter.splits.name.contains("feat"))
        // Segments
        XCTAssertTrue(resultAfter.segments.segments.contains("s1"))
        XCTAssertEqual(userKey, resultAfter.segments.userKey)
        // Impressions
        XCTAssertTrue(resultAfter.impressions.body.contains("key1"))
        XCTAssertEqual("split", resultAfter.impressions.testName)
        // Events
        XCTAssertTrue(resultAfter.events.contains("key1"))
        // Impressions
        XCTAssertTrue(resultAfter.impressionsCount.contains("pepe"))
        // Unique Keys
        XCTAssertEqual(userKey, resultAfter.uniqueKeys.userKey)
        XCTAssertTrue(resultAfter.uniqueKeys.features.contains("split1"))
        // Attributes
        XCTAssertEqual(userKey, resultAfter.attributes.userKey)
        XCTAssertTrue(resultAfter.attributes.attributes.contains("att1"))
        // RBS
        XCTAssertEqual("test_rbs", resultAfter.ruleBasedSegments.name)
        XCTAssertTrue(resultAfter.ruleBasedSegments.body.contains("test_"))
    }

    struct DataResult {
        let splits: (name: String, body: String)
        let segments: (userKey: String, segments: String)
        let largeSegments: (userKey: String, segments: String)
        let impressions: (testName: String, body: String)
        let events: String
        let impressionsCount: String
        let uniqueKeys: (userKey: String, features: String)
        let attributes: (userKey: String, attributes: String)
        let ruleBasedSegments: (name: String, body: String)
    }

    private func loadData(dbHelper: CoreDataHelper) -> DataResult {
        var result: DataResult?
        dbHelper.performAndWait {
            result = DataResult(splits: dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }.map { (name: $0.name,
                                                                                                                body: $0.body)}[0],
                                segments: dbHelper.fetch(entity: .mySegment).compactMap { $0 as? MySegmentEntity }.map { (userKey: $0.userKey!,
                                                                                                                          segments: $0.segmentList!) }[0],
                                largeSegments: dbHelper.fetch(entity: .myLargeSegment).compactMap { $0 as? MySegmentEntity }.map { (userKey: $0.userKey!,
                                                                                                                                    segments: $0.segmentList!) }[0],
                                impressions: dbHelper.fetch(entity: .impression).compactMap { $0 as? ImpressionEntity }.map { (testName: $0.testName,
                                                                                                                               body: $0.body) }[0],
                                events: dbHelper.fetch(entity: .event).compactMap { $0 as? EventEntity }.map { $0.body }[0],
                                impressionsCount: dbHelper.fetch(entity: .impressionsCount).compactMap { $0 as? ImpressionsCountEntity }.map { $0.body }[0],
                                uniqueKeys: dbHelper.fetch(entity: .uniqueKey).compactMap { $0 as? UniqueKeyEntity }.map { (userKey: $0.userKey,
                                                                                                                            features: $0.featureList) }[0],
                                attributes: dbHelper.fetch(entity: .attribute).compactMap { $0 as? AttributeEntity }.map { (userKey: $0.userKey!,
                                                                                                                            attributes: $0.attributes!) }[0],
                                ruleBasedSegments: dbHelper.fetch(entity: .ruleBasedSegment).compactMap { $0 as? RuleBasedSegmentEntity }.map { (name: $0.name, body: $0.body )}[0]
            )
        }
        return result!
    }

    private func insertData(dbHelper: CoreDataHelper) {
        db.splitDao.insertOrUpdate(splits: TestingHelper.createSplits().suffix(1))

        let msChange = SegmentChange(segments: ["s1"])
        db.mySegmentsDao.update(userKey: userKey, change: msChange)

        let mlsChange = SegmentChange(segments: ["s1"])
        db.myLargeSegmentsDao.update(userKey: userKey, change: mlsChange)

        db.impressionDao.insert(TestingHelper.createKeyImpressions().suffix(1))
        db.eventDao.insert(TestingHelper.createEvents(count: 1, randomId: false).suffix(1))
        db.impressionsCountDao.insert(ImpressionsCountPerFeature(storageId: "id1", feature: "pepe", timeframe: 111111, count: 1) )
        db.uniqueKeyDao.insert(UniqueKey(userKey: IntegrationHelper.dummyUserKey, features: ["split1"]))
        db.attributesDao.update(userKey: userKey, attributes: ["att1": 1])
        db.ruleBasedSegmentDao.insertOrUpdate(segment: TestingHelper.createRuleBasedSegment())
    }

    private func createDbHelper() -> CoreDataHelper {
        return IntegrationCoreDataHelper.get(databaseName: "test",
                                             dispatchQueue: DispatchQueue.global())
    }

    private func createCipher(fromLevel: SplitEncryptionLevel,
                              toLevel: SplitEncryptionLevel,
                              dbHelper: CoreDataHelper) throws -> DbCipher {
        return try DbCipher(cipherKey: IntegrationHelper.dummyCipherKey,
                            from: fromLevel,
                            to: toLevel,
                            coreDataHelper: dbHelper)
    }
}

