//
//  RuleBasedSegmentStorageTest.swift
//  SplitTests
//
//  Created by Split on 18/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class RuleBasedSegmentStorageTest: XCTestCase {

    private var persistentStorageStub: PersistentRuleBasedSegmentsStorageStub!
    private var ruleBasedSegmentsStorage: DefaultRuleBasedSegmentsStorage!

    override func setUp() {
        ruleBasedSegmentsStorage = DefaultRuleBasedSegmentsStorage(
            persistentRuleBasedSegmentsStorage: createPersistentStorageStub()
        )
        ruleBasedSegmentsStorage.loadLocal()
    }

    override func tearDown() {
        ruleBasedSegmentsStorage.clear()
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 123)

        let segment = ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1")
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, "segment_1")
    }

    func testLoadLocalAfterClear() {
        ruleBasedSegmentsStorage.clear()

        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, -1)
        XCTAssertNil(ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1"))

        ruleBasedSegmentsStorage.loadLocal()

        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 123)
        let segment = ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1")
        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, "segment_1")
    }

    func testLoadLocalWithUpdatedPersistentStorage() {
        let customMock = MockPersistentRuleBasedSegmentsStorage()
        let persistentStorageStub = PersistentRuleBasedSegmentsStorageStub(delegate: customMock)
        let storage = DefaultRuleBasedSegmentsStorage(
            persistentRuleBasedSegmentsStorage: persistentStorageStub
        )
        storage.loadLocal()

        // Initial state - verify segment_1 exists
        XCTAssertEqual(storage.changeNumber, 123)
        XCTAssertNotNil(storage.get(segmentName: "segment_1", matchingKey: "key1"))
        XCTAssertNil(storage.get(segmentName: "new_segment", matchingKey: "key1"))

        // Update the mock's data
        customMock.updateSnapshotData(
            segments: [
                createSegment(name: "new_segment", trafficType: "new_tt"),
                createSegment(name: "segment_2", trafficType: "tt_2"),
                createSegment(name: "segment_1", trafficType: "tt_1", status: .archived)
            ],
            changeNumber: 456
        )

        storage.loadLocal()

        // Verify the storage was updated with the new data
        XCTAssertEqual(storage.changeNumber, 456)
        XCTAssertNil(storage.get(segmentName: "segment_1", matchingKey: "key1"))
        XCTAssertNotNil(storage.get(segmentName: "new_segment", matchingKey: "key1"))
        XCTAssertNotNil(storage.get(segmentName: "segment_2", matchingKey: "key1"))
    }

    func testLoadLocalWithArchivedSegments() {
        let customMock = MockPersistentRuleBasedSegmentsStorage()
        customMock.updateSnapshotData(
            segments: [
                createSegment(name: "active_segment", trafficType: "tt_active"),
                createSegment(name: "archived_segment", trafficType: "tt_archived", status: .archived)
            ],
            changeNumber: 789
        )

        persistentStorageStub = PersistentRuleBasedSegmentsStorageStub(delegate: customMock)
        let storage = DefaultRuleBasedSegmentsStorage(
            persistentRuleBasedSegmentsStorage: persistentStorageStub
        )
        storage.loadLocal()

        // Verify only active segments are loaded
        XCTAssertEqual(storage.changeNumber, 789)
        XCTAssertNotNil(storage.get(segmentName: "active_segment", matchingKey: "key1"))
        XCTAssertNil(storage.get(segmentName: "archived_segment", matchingKey: "key1"))
    }
    
    func testGetExistingSegment() {
        let segment = ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1")

        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, "segment_1")
        XCTAssertEqual(segment?.trafficTypeName, "tt_1")
    }

    func testGetNonExistingSegment() {
        let segment = ruleBasedSegmentsStorage.get(segmentName: "non_existing", matchingKey: "key1")

        XCTAssertNil(segment)
    }

    func testGetWithCaseInsensitiveSegmentName() {
        let segment = ruleBasedSegmentsStorage.get(segmentName: "SeGmEnT_1", matchingKey: "key1")

        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, "segment_1")
    }

    func testGetWithUnparsedSegment() {
        let unparsedSegment = RuleBasedSegment()
        unparsedSegment.name = "unparsed_segment"
        unparsedSegment.json = """
        {
            "name": "unparsed_segment",
            "trafficTypeName": "tt_unparsed",
            "status": "ACTIVE",
            "changeNumber": 456
        }
        """
        unparsedSegment.isParsed = false

        // Update storage with the unparsed segment
        ruleBasedSegmentsStorage.update(
            toAdd: Set([unparsedSegment]),
            toRemove: Set(),
            changeNumber: 456
        )

        let segment = ruleBasedSegmentsStorage.get(segmentName: "unparsed_segment", matchingKey: "key1")

        XCTAssertNotNil(segment)
        XCTAssertEqual(segment?.name, "unparsed_segment")
        XCTAssertEqual(segment?.trafficTypeName, "tt_unparsed")
        XCTAssertEqual(segment?.changeNumber, 456)
        XCTAssertTrue(segment?.isParsed ?? false)
    }
    
    func testContainsExistingSegments() {
        let result = ruleBasedSegmentsStorage.contains(segmentNames: ["segment_1", "segment_2"])

        XCTAssertTrue(result)
    }

    func testContainsNonExistingSegments() {
        let result = ruleBasedSegmentsStorage.contains(segmentNames: ["non_existing_1", "non_existing_2"])

        XCTAssertFalse(result)
    }

    func testContainsMixedSegments() {
        let result = ruleBasedSegmentsStorage.contains(segmentNames: ["segment_1", "non_existing"])

        XCTAssertTrue(result)
    }

    func testContainsWithCaseInsensitiveSegmentNames() {
        let result = ruleBasedSegmentsStorage.contains(segmentNames: ["SeGmEnT_1", "SEGMENT_2"])

        XCTAssertTrue(result)
    }
    
    func testUpdateAddSegments() {
        let newSegment1 = createSegment(name: "new_segment_1", trafficType: "tt_new_1")
        let newSegment2 = createSegment(name: "new_segment_2", trafficType: "tt_new_2")

        let updated = ruleBasedSegmentsStorage.update(
            toAdd: Set([newSegment1, newSegment2]),
            toRemove: Set(),
            changeNumber: 456
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 456)

        let segment1 = ruleBasedSegmentsStorage.get(segmentName: "new_segment_1", matchingKey: "key1")
        let segment2 = ruleBasedSegmentsStorage.get(segmentName: "new_segment_2", matchingKey: "key1")
        XCTAssertNotNil(segment1)
        XCTAssertNotNil(segment2)

        XCTAssertTrue(persistentStorageStub.updateCalled)
        XCTAssertEqual(persistentStorageStub.lastChangeNumber, 456)
        XCTAssertEqual(persistentStorageStub.lastAddedSegments?.count, 2)
        XCTAssertTrue(persistentStorageStub.lastAddedSegments?.contains(where: { $0.name == "new_segment_1" }) ?? false)
        XCTAssertTrue(persistentStorageStub.lastAddedSegments?.contains(where: { $0.name == "new_segment_2" }) ?? false)
    }

    func testUpdateRemoveSegments() {
        let updated = ruleBasedSegmentsStorage.update(
            toAdd: Set(),
            toRemove: Set([createSegment(name: "segment_1"), createSegment(name: "segment_2")]),
            changeNumber: 456
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 456)

        let segment1 = ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1")
        let segment2 = ruleBasedSegmentsStorage.get(segmentName: "segment_2", matchingKey: "key1")
        XCTAssertNil(segment1)
        XCTAssertNil(segment2)

        XCTAssertTrue(persistentStorageStub.updateCalled)
        XCTAssertEqual(persistentStorageStub.lastChangeNumber, 456)
        XCTAssertEqual(persistentStorageStub.lastRemovedSegments?.count, 2)
        XCTAssertTrue(persistentStorageStub.lastRemovedSegments?.contains(where: { $0.name == "segment_1" }) ?? false)
        XCTAssertTrue(persistentStorageStub.lastRemovedSegments?.contains(where: { $0.name == "segment_2" }) ?? false)
    }

    func testUpdateAddAndRemoveSegments() {
        let newSegment = createSegment(name: "new_segment", trafficType: "tt_new")

        let updated = ruleBasedSegmentsStorage.update(
            toAdd: Set([newSegment]),
            toRemove: Set([createSegment(name: "segment_1")]),
            changeNumber: 456
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 456)

        let addedSegment = ruleBasedSegmentsStorage.get(segmentName: "new_segment", matchingKey: "key1")
        let removedSegment = ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1")
        XCTAssertNotNil(addedSegment)
        XCTAssertNil(removedSegment)

        XCTAssertTrue(persistentStorageStub.updateCalled)
        XCTAssertEqual(persistentStorageStub.lastChangeNumber, 456)
        XCTAssertEqual(persistentStorageStub.lastAddedSegments?.count, 1)
        XCTAssertEqual(persistentStorageStub.lastRemovedSegments?.count, 1)
        XCTAssertTrue(persistentStorageStub.lastAddedSegments?.contains(where: { $0.name == "new_segment" }) ?? false)
        XCTAssertTrue(persistentStorageStub.lastRemovedSegments?.contains(where: { $0.name == "segment_1" }) ?? false)
    }

    func testUpdateWithNoChanges() {
        let updated = ruleBasedSegmentsStorage.update(
            toAdd: Set(),
            toRemove: Set(),
            changeNumber: 456
        )

        XCTAssertFalse(updated)
        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, 456)

        // Verify persistent storage was still updated with the new change number
        XCTAssertTrue(persistentStorageStub.updateCalled)
        XCTAssertEqual(persistentStorageStub.lastChangeNumber, 456)
        XCTAssertEqual(persistentStorageStub.lastAddedSegments?.count, 0)
        XCTAssertEqual(persistentStorageStub.lastRemovedSegments?.count, 0)
    }

    func testClear() {
        ruleBasedSegmentsStorage.clear()

        XCTAssertEqual(ruleBasedSegmentsStorage.changeNumber, -1)
        XCTAssertNil(ruleBasedSegmentsStorage.get(segmentName: "segment_1", matchingKey: "key1"))
        XCTAssertNil(ruleBasedSegmentsStorage.get(segmentName: "segment_2", matchingKey: "key1"))

        XCTAssertTrue(persistentStorageStub.clearCalled)
    }

    private func createPersistentStorageStub() -> PersistentRuleBasedSegmentsStorageStub {
        let delegate = MockPersistentRuleBasedSegmentsStorage()
        persistentStorageStub = PersistentRuleBasedSegmentsStorageStub(delegate: delegate)
        return persistentStorageStub
    }

    private func createSegment(name: String, trafficType: String = "tt_default", status: Status = .active) -> RuleBasedSegment {
        let segment = RuleBasedSegment()
        segment.name = name
        segment.trafficTypeName = trafficType
        segment.status = status
        segment.changeNumber = Int64(Date.nowMillis())
        segment.isParsed = true
        return segment
    }
}

private class MockPersistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorage {
    private var segments = [
        createSegment(name: "segment_1", trafficType: "tt_1"),
        createSegment(name: "segment_2", trafficType: "tt_2"),
        createSegment(name: "segment_3", trafficType: "tt_3")
    ]
    private var snapshotChangeNumber: Int64 = 123

    func getSnapshot() -> RuleBasedSegmentsSnapshot {
        return RuleBasedSegmentsSnapshot(changeNumber: snapshotChangeNumber, segments: segments)
    }

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) {
        // No-op for the mock
    }

    func clear() {
        // No-op for the mock
    }

    func updateSnapshotData(segments: [RuleBasedSegment], changeNumber: Int64) {
        self.segments = segments
        self.snapshotChangeNumber = changeNumber
    }

    private static func createSegment(name: String, trafficType: String) -> RuleBasedSegment {
        let segment = RuleBasedSegment()
        segment.name = name
        segment.trafficTypeName = trafficType
        segment.status = .active
        segment.changeNumber = 123
        segment.isParsed = true
        return segment
    }
}
