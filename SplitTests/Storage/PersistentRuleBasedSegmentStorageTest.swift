//
//  PersistentRuleBasedSegmentStorageTest.swift
//  SplitTests
//
//  Created by Split on 18/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class PersistentRuleBasedSegmentStorageTest: XCTestCase {

    var persistentStorage: PersistentRuleBasedSegmentsStorage!
    var ruleBasedSegmentDao: RuleBasedSegmentDaoStub!
    var generalInfoDao: GeneralInfoDaoStub!
    var generalInfoStorage: GeneralInfoStorage!

    override func setUp() {
        ruleBasedSegmentDao = RuleBasedSegmentDaoStub()
        generalInfoDao = GeneralInfoDaoStub()
        generalInfoStorage = DefaultGeneralInfoStorage(generalInfoDao: generalInfoDao)

        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.ruleBasedSegmentDao = ruleBasedSegmentDao
        daoProvider.generalInfoDao = generalInfoDao

        persistentStorage = DefaultPersistentRuleBasedSegmentsStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider),
            generalInfoStorage: generalInfoStorage
        )
    }

    func testUpdateAddsAndRemovesSegments() {
        let segmentsToAdd = Set([
            createSegment(name: "segment_1", trafficType: "tt_1"),
            createSegment(name: "segment_2", trafficType: "tt_2")
        ])

        let segmentsToRemove = Set([
            createSegment(name: "segment_3", trafficType: "tt_3"),
            createSegment(name: "segment_4", trafficType: "tt_4")
        ])

        persistentStorage.update(toAdd: segmentsToAdd, toRemove: segmentsToRemove, changeNumber: 123)

        XCTAssertEqual(2, ruleBasedSegmentDao.insertedSegments.count)
        XCTAssertTrue(ruleBasedSegmentDao.insertedSegments.contains { $0.name == "segment_1" })
        XCTAssertTrue(ruleBasedSegmentDao.insertedSegments.contains { $0.name == "segment_2" })

        XCTAssertEqual(2, ruleBasedSegmentDao.deletedSegments?.count)
        XCTAssertTrue(ruleBasedSegmentDao.deletedSegments?.contains("segment_3") ?? false)
        XCTAssertTrue(ruleBasedSegmentDao.deletedSegments?.contains("segment_4") ?? false)

        XCTAssertEqual(123, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
    }

    func testUpdateWithEmptySegments() {
        persistentStorage.update(toAdd: Set(), toRemove: Set(), changeNumber: 456)

        XCTAssertEqual(0, ruleBasedSegmentDao.insertedSegments.count)
        XCTAssertNil(ruleBasedSegmentDao.deletedSegments)

        XCTAssertEqual(456, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
    }

    func testGetSnapshot() {
        let segment1 = createSegment(name: "segment_1", trafficType: "tt_1")
        let segment2 = createSegment(name: "segment_2", trafficType: "tt_2")
        ruleBasedSegmentDao.segments = [segment1, segment2]
        generalInfoStorage.setRuleBasedSegmentsChangeNumber(changeNumber: 789)

        let snapshot = persistentStorage.getSnapshot()

        XCTAssertEqual(789, snapshot.changeNumber)
        XCTAssertEqual(2, snapshot.segments.count)
        XCTAssertTrue(snapshot.segments.contains { $0.name == "segment_1" })
        XCTAssertTrue(snapshot.segments.contains { $0.name == "segment_2" })
    }
    
    func testClear() {
        persistentStorage.clear()

        XCTAssertTrue(ruleBasedSegmentDao.deleteAllCalled)

        XCTAssertEqual(-1, generalInfoStorage.getRuleBasedSegmentsChangeNumber())
    }

    private func createSegment(name: String, trafficType: String, status: Status = .active) -> RuleBasedSegment {
        let segment = RuleBasedSegment()
        segment.name = name
        segment.trafficTypeName = trafficType
        segment.status = status
        segment.changeNumber = Int64(Date.nowMillis())
        segment.isParsed = true
        return segment
    }
}
