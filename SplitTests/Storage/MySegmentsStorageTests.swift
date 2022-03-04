//
//  MySegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MySegmentsStorageTests: XCTestCase {

    var persistentStorage: PersistentMySegmentsStorageStub!
    var mySegmentsStorage: MySegmentsStorage!
    var userKey = "dummyKey"
    var dummySegments = ["s1", "s2", "s3"]

    override func setUp() {
        persistentStorage = PersistentMySegmentsStorageStub()
        mySegmentsStorage = DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentStorage)
    }

    func testNoLoaded() {
        let segments = mySegmentsStorage.getAll(forKey: userKey)

        XCTAssertEqual(0, segments.count)
    }

    func testGetMySegmentsAfterLoad() {
        persistentStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        let segments1 = mySegmentsStorage.getAll(forKey: "otherKey")

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, segments1.count)
    }

    func testUpdateSegments() {
        persistentStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        mySegmentsStorage.set(["n1", "n2"], forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)
        let otherSegments = mySegmentsStorage.getAll(forKey: "otherKey")

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(2, persistedSegments.count)
        XCTAssertTrue(persistedSegments.contains("n1"))
        XCTAssertTrue(persistedSegments.contains("n2"))

        XCTAssertEqual(2, newSegments.count)
        XCTAssertTrue(newSegments.contains("n1"))
        XCTAssertTrue(newSegments.contains("n2"))

        XCTAssertEqual(0, otherSegments.count)
    }

    func testUpdateEmptySegments() {
        persistentStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        mySegmentsStorage.set([String](), forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments.count)
    }

    func testClear() {
        let otherKey = "otherKey"
        persistentStorage.persistedSegments = [userKey : dummySegments, otherKey: ["s1"]]
        mySegmentsStorage.loadLocal(forKey: userKey)
        mySegmentsStorage.loadLocal(forKey: otherKey)
        let segments = mySegmentsStorage.getAll(forKey: userKey)
        mySegmentsStorage.clear(forKey: userKey)
        let newSegments = mySegmentsStorage.getAll(forKey: userKey)
        let otherSegments = mySegmentsStorage.getAll(forKey: otherKey)
        let persistedSegments = persistentStorage.getSnapshot(forKey: userKey)
        let otherPersistedSegments = persistentStorage.getSnapshot(forKey: otherKey)

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments.count)

        XCTAssertEqual(1, otherSegments.count)
        XCTAssertTrue(otherSegments.contains("s1"))

        XCTAssertEqual(1, otherPersistedSegments.count)
        XCTAssertTrue(otherPersistedSegments.contains("s1"))
    }

}
