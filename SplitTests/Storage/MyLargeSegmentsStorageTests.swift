//
//  MyLargeSegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MyLargeSegmentsStorageTests: XCTestCase {

    var persistentStorage: PersistentMySegmentsStorageMock!
    var mySegmentsStorage: MySegmentsStorage!
    var userKey = "dummyKey"
    var dummyChange = SegmentChange(segments: ["s1", "s2", "s3"], changeNumber: 100)

    override func setUp() {
        persistentStorage = PersistentMySegmentsStorageMock()
        mySegmentsStorage = MyLargeSegmentsStorage(persistentStorage: persistentStorage)
    }

    func testNoLoaded() {
        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)

        XCTAssertEqual(-1, changeNum)
        XCTAssertEqual(0, segments.count)
    }

    func testGetMySegmentsAfterLoad() {
        let otherKey = "otherKey"
        persistentStorage.persistedSegments = [userKey: dummyChange]
        mySegmentsStorage.loadLocal(forKey: userKey)

        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let changeNum1 = mySegmentsStorage.changeNumber(forKey: otherKey)

        let segments = mySegmentsStorage.getAll(forKey: userKey)
        let segments1 = mySegmentsStorage.getAll(forKey: otherKey)

        XCTAssertEqual(100, changeNum)
        XCTAssertEqual(-1, changeNum1)
        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, segments1.count)
    }

    func testUpdateSegments() {
        persistentStorage.persistedSegments = [userKey : dummyChange]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        mySegmentsStorage.set(SegmentChange(segments: ["n1", "n2"], changeNumber: 55), forKey: userKey)

        let newChangeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)
        let otherSegments = mySegmentsStorage.getAll(forKey: "otherKey")

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(2, persistedSegments?.segments.count)
        XCTAssertTrue(persistedSegments?.segments.compactMap { $0.name } .contains("n1") ?? false)
        XCTAssertTrue(persistedSegments?.segments.compactMap { $0.name } .contains("n2") ?? false)

        XCTAssertEqual(2, newSegments.count)
        XCTAssertTrue(newSegments.contains("n1"))
        XCTAssertTrue(newSegments.contains("n2"))

        XCTAssertEqual(0, otherSegments.count)
    }

    func testUpdateEmptySegments() {
        persistentStorage.persistedSegments = [userKey : dummyChange]
        mySegmentsStorage.loadLocal(forKey: userKey)
        
        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)

        mySegmentsStorage.set(SegmentChange(segments: []), forKey: userKey)
        let newChangeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)

        XCTAssertEqual(100, changeNum)
        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(-1, newChangeNum)
        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments?.segments.count)
    }

    func testClear() {
        let otherKey = "otherKey"
        persistentStorage.persistedSegments = [userKey : dummyChange,
                                               otherKey: SegmentChange(segments: ["s1"], changeNumber: 44)
        ]

        mySegmentsStorage.loadLocal(forKey: userKey)
        mySegmentsStorage.loadLocal(forKey: otherKey)
        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        mySegmentsStorage.clear(forKey: userKey)

        let newChangeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        
        let otherChangeNum = mySegmentsStorage.changeNumber(forKey: otherKey)
        let otherSegments = mySegmentsStorage.getAll(forKey: otherKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)
        let otherPersistedSegments = persistentStorage.getSnapshot(forKey: otherKey)

        XCTAssertEqual(100, changeNum)
        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(-1, newChangeNum)
        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments?.segments.count)

        XCTAssertEqual(44, otherChangeNum)
        XCTAssertEqual(1, otherSegments.count)
        XCTAssertTrue(otherSegments.contains("s1"))

        XCTAssertEqual(1, otherPersistedSegments?.segments.count)
        XCTAssertTrue(otherPersistedSegments?.segments.compactMap { $0.name } .contains("s1") ?? false)
    }

    func testChangeNumber() {
        persistentStorage.persistedSegments = [userKey : dummyChange]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let cn1 = mySegmentsStorage.changeNumber(forKey: userKey)

        mySegmentsStorage.set(SegmentChange(segments: [], changeNumber: 200), forKey: userKey)
        let cn2 = mySegmentsStorage.changeNumber(forKey: userKey)

        XCTAssertEqual(100, cn1)
        XCTAssertEqual(200, cn2)
    }

    func testClearAll() {
        let otherKey = "otherKey"
        persistentStorage.persistedSegments = [userKey : dummyChange,
                                               otherKey: SegmentChange(segments: ["s1"], changeNumber: 44)
        ]
        mySegmentsStorage.loadLocal(forKey: userKey)
        mySegmentsStorage.loadLocal(forKey: otherKey)

        let changeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        let otherChangeNum = mySegmentsStorage.changeNumber(forKey: otherKey)
        let otherSegments = mySegmentsStorage.getAll(forKey: otherKey)

        mySegmentsStorage.clear()

        let newChangeNum = mySegmentsStorage.changeNumber(forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let newOtherChangeNum = mySegmentsStorage.changeNumber(forKey: otherKey)
        let newOtherSegments = mySegmentsStorage.getAll(forKey: otherKey)

        XCTAssertEqual(100, changeNum)
        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))
        XCTAssertEqual(44, otherChangeNum)
        XCTAssertEqual(1, otherSegments.count)
        XCTAssertTrue(otherSegments.contains("s1"))
        XCTAssertEqual(newChangeNum, -1)
        XCTAssertEqual(newSegments.count, 0)
        XCTAssertEqual(newOtherChangeNum, -1)
        XCTAssertEqual(newOtherSegments.count, 0)
    }
}
