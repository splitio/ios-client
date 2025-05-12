//
//  RuleBasedSegmentDaoTest.swift
//  SplitTests
//
//  Created by Split on 18/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class RuleBasedSegmentDaoTest: XCTestCase {

    var ruleBasedSegmentDao: RuleBasedSegmentDao!
    var ruleBasedSegmentDaoAes128Cbc: RuleBasedSegmentDao!

    override func setUp() {
        let cipherKey = IntegrationHelper.dummyCipherKey
        let queue = DispatchQueue(label: "rule based segment dao test")
        ruleBasedSegmentDao = CoreDataRuleBasedSegmentDao(
            coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test", dispatchQueue: queue)
        )

        ruleBasedSegmentDaoAes128Cbc = CoreDataRuleBasedSegmentDao(
            coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test", dispatchQueue: queue),
            cipher: DefaultCipher(cipherKey: cipherKey)
        )

        let segments = createRuleBasedSegments()
        ruleBasedSegmentDao.insertOrUpdate(segments: segments)
        ruleBasedSegmentDaoAes128Cbc.insertOrUpdate(segments: segments)
    }

    override func tearDown() {
        ruleBasedSegmentDao.deleteAll()
        ruleBasedSegmentDaoAes128Cbc.deleteAll()
        super.tearDown()
    }

    func testGetUpdateSeveralPlainText() {
        getUpdateSeveral(dao: ruleBasedSegmentDao)
    }

    func testGetUpdateSeveralAes128Cbc() {
        getUpdateSeveral(dao: ruleBasedSegmentDaoAes128Cbc)
    }

    func getUpdateSeveral(dao: RuleBasedSegmentDao) {
        let segments = dao.getAll()

        dao.insertOrUpdate(segments: [newRuleBasedSegment(name: "segment_0", trafficType: "ttype")])
        let segmentsUpd = dao.getAll()

        XCTAssertEqual(5, segments.count)
        XCTAssertEqual(5, segmentsUpd.count)
        XCTAssertEqual(1, segments.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, segmentsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }

    func testGetUpdate() {
        getUpdate(dao: ruleBasedSegmentDao)
    }

    func testGetUpdateAes128Cbc() {
        getUpdate(dao: ruleBasedSegmentDaoAes128Cbc)
    }

    func getUpdate(dao: RuleBasedSegmentDao) {
        let segments = dao.getAll()

        dao.insertOrUpdate(segment: newRuleBasedSegment(name: "segment_0", trafficType: "ttype"))
        let segmentsUpd = dao.getAll()

        XCTAssertEqual(5, segments.count)
        XCTAssertEqual(5, segmentsUpd.count)
        XCTAssertEqual(1, segments.filter { $0.trafficTypeName == "tt_0" }.count)
        XCTAssertEqual(1, segmentsUpd.filter { $0.trafficTypeName == "ttype" }.count)
    }

    func testDeleteAllPlainText() {
        deleteAll(dao: ruleBasedSegmentDao)
    }

    func testDeleteAllAes128Cbc() {
        deleteAll(dao: ruleBasedSegmentDaoAes128Cbc)
    }

    func deleteAll(dao: RuleBasedSegmentDao) {
        let segmentsBefore = dao.getAll()
        dao.deleteAll()
        let segmentsAfter = dao.getAll()

        XCTAssertEqual(5, segmentsBefore.count)
        XCTAssertEqual(0, segmentsAfter.count)
    }

    func testCreateGetPlainText() {
        createGet(dao: ruleBasedSegmentDao)
    }

    func testCreateGetAes128Cbc() {
        createGet(dao: ruleBasedSegmentDaoAes128Cbc)
    }

    func createGet(dao: RuleBasedSegmentDao) {
        let segments = dao.getAll()

        dao.insertOrUpdate(segment: newRuleBasedSegment(name: "segment_100", trafficType: "ttype"))
        let segmentsUpd = dao.getAll()

        XCTAssertEqual(5, segments.count)
        XCTAssertEqual(6, segmentsUpd.count)
    }

    func testDeleteSpecificSegments() {
        let segmentsBefore = ruleBasedSegmentDao.getAll()
        XCTAssertEqual(5, segmentsBefore.count)

        ruleBasedSegmentDao.delete(["segment_0", "segment_1"])
        let segmentsAfter = ruleBasedSegmentDao.getAll()

        XCTAssertEqual(3, segmentsAfter.count)
        XCTAssertNil(segmentsAfter.first(where: { $0.name == "segment_0" }))
        XCTAssertNil(segmentsAfter.first(where: { $0.name == "segment_1" }))
    }

    func testSyncInsertOrUpdate() {
        let newSegment = newRuleBasedSegment(name: "segment_sync", trafficType: "sync_tt")
        ruleBasedSegmentDao.syncInsertOrUpdate(segment: newSegment)

        let segments = ruleBasedSegmentDao.getAll()
        let syncSegment = segments.first(where: { $0.name == "segment_sync" })

        XCTAssertNotNil(syncSegment)
        XCTAssertEqual("sync_tt", syncSegment?.trafficTypeName)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two daos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(databaseName: "test",
                                                  dispatchQueue: DispatchQueue(label: "rule based segment dao test"))
        ruleBasedSegmentDao = CoreDataRuleBasedSegmentDao(coreDataHelper: helper)
        ruleBasedSegmentDaoAes128Cbc = CoreDataRuleBasedSegmentDao(coreDataHelper: helper,
                                                                  cipher: cipher)

        // create segments and get one encrypted segment name
        let segments = createRuleBasedSegments()
        let testNameEnc = cipher.encrypt(segments[0].name) ?? "fail"

        // Insert encrypted segments
        for segment in segments {
            ruleBasedSegmentDaoAes128Cbc.syncInsertOrUpdate(segment: segment)
        }

        // load segments and filter them by encrypted segment name
        let loadSegment = getBy(testName: testNameEnc, coreDataHelper: helper)

        let segment = try? Json.decodeFrom(json: loadSegment.body ?? "", to: RuleBasedSegment.self)

        XCTAssertNotNil(loadSegment)
        XCTAssertFalse(loadSegment.name?.contains("segment_") ?? true)
        XCTAssertFalse(loadSegment.body?.contains("tt_") ?? true)
        XCTAssertNil(segment)
    }

    func getBy(testName: String, coreDataHelper: CoreDataHelper) -> (name: String?, body: String?) {
        var name: String? = nil
        var body: String? = nil
        coreDataHelper.performAndWait {
            let predicate = NSPredicate(format: "name == %@", testName)
            let entities = coreDataHelper.fetch(entity: .ruleBasedSegment,
                                               where: predicate,
                                               rowLimit: 1).compactMap { return $0 as? RuleBasedSegmentEntity }
            if entities.count > 0 {
                name = entities[0].name
                body = entities[0].body
            }
        }
        return (name: name, body: body)
    }

    private func createRuleBasedSegments() -> [RuleBasedSegment] {
        var segments = [RuleBasedSegment]()
        for i in 0..<5 {
            let segment = newRuleBasedSegment(name: "segment_\(i)", trafficType: "tt_\(i)")
            segments.append(segment)
        }
        return segments
    }

    private func newRuleBasedSegment(name: String, trafficType: String) -> RuleBasedSegment {
        let segment = RuleBasedSegment()
        segment.name = name
        segment.trafficTypeName = trafficType
        segment.status = .active
        segment.changeNumber = Int64(Date.nowMillis())
        
        // Add some conditions for testing
        let condition = Condition()
        condition.matcherGroup = MatcherGroup()
        condition.matcherGroup?.matchers = [Matcher()]
        condition.matcherGroup?.matchers?[0].keySelector = KeySelector()
        condition.matcherGroup?.matchers?[0].keySelector?.attribute = nil
        condition.matcherGroup?.matchers?[0].matcherType = MatcherType.containsString
        condition.matcherGroup?.matchers?[0].negate = false
        condition.matcherGroup?.matchers?[0].userDefinedSegmentMatcherData = nil
        condition.matcherGroup?.matchers?[0].unaryNumericMatcherData = nil
        condition.matcherGroup?.matchers?[0].betweenMatcherData = nil
        condition.matcherGroup?.matchers?[0].dependencyMatcherData = nil
        condition.matcherGroup?.matchers?[0].booleanMatcherData = nil
        condition.matcherGroup?.matchers?[0].stringMatcherData = "value1,value2"
        condition.matcherGroup?.matchers?[0].whitelistMatcherData = WhitelistMatcherData()
        condition.matcherGroup?.matchers?[0].whitelistMatcherData?.whitelist = ["value1", "value2"]

        segment.conditions = [condition]

        let excluded = Excluded()
        excluded.keys = Set(["key1", "key2"])
        excluded.segments = Set([
            ExcludedSegment(name: "segment1", type: .standard),
            ExcludedSegment(name: "segment2", type: .standard)])
        segment.excluded = excluded

        return segment
    }
}
