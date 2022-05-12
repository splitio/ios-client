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

    var mySegmentsStorage: MySegmentsStorage!
    var persistentStorage: PersistentMySegmentsStorageStub!
    
    override func setUp() {
        persistentStorage = PersistentMySegmentsStorageStub()
        mySegmentsStorage = DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentStorage)
    }

    func testNoLoaded() {
        let segments = mySegmentsStorage.getAll()

        XCTAssertEqual(0, segments.count)
    }

    func testGetMySegmentsAfterLoad() {
        persistentStorage.segments = ["s1", "s2", "s3"]
        mySegmentsStorage.loadLocal()
        let segments = mySegmentsStorage.getAll()

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))
    }

    func testUpdateSegments() {
        persistentStorage.segments = ["s1", "s2", "s3"]
        mySegmentsStorage.loadLocal()
        let segments = mySegmentsStorage.getAll()
        mySegmentsStorage.set(["n1", "n2"])
        let newSegments = mySegmentsStorage.getAll()
        let persistedSegments = persistentStorage.getSnapshot()

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(2, persistedSegments.count)
        XCTAssertTrue(persistedSegments.contains("n1"))
        XCTAssertTrue(persistedSegments.contains("n2"))

        XCTAssertEqual(2, newSegments.count)
        XCTAssertTrue(newSegments.contains("n1"))
        XCTAssertTrue(newSegments.contains("n2"))
    }

    func testUpdateEmptySegments() {
        persistentStorage.segments = ["s1", "s2", "s3"]
        mySegmentsStorage.loadLocal()
        let segments = mySegmentsStorage.getAll()
        mySegmentsStorage.set([String]())
        let newSegments = mySegmentsStorage.getAll()
        let persistedSegments = persistentStorage.getSnapshot()

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments.count)
    }

    func testClear() {
        persistentStorage.segments = ["s1", "s2", "s3"]
        mySegmentsStorage.loadLocal()
        let segments = mySegmentsStorage.getAll()
        mySegmentsStorage.clear()
        let newSegments = mySegmentsStorage.getAll()
        let persistedSegments = persistentStorage.getSnapshot()

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments.count)
    }

    override func tearDown() {

    }
}
