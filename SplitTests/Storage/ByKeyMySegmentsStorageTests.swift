//
//  ByKeyMySegmentsStorageTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 03-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ByKeyMySegmentsStorageTests: XCTestCase {

    var byKeyMySegmentsStorage: ByKeyMySegmentsStorage!
    var userKey = "dummyKey"
    var mySegmentsStorage: MySegmentsStorageStub!
    var dummySegments = Set(["s1", "s2", "s3"])
    
    override func setUp() {
        mySegmentsStorage = MySegmentsStorageStub()
        byKeyMySegmentsStorage = DefaultByKeyMySegmentsStorage(mySegmentsStorage: mySegmentsStorage,                                                          userKey: userKey)
    }

    func testNoLoaded() {
        let segments = byKeyMySegmentsStorage.getAll()
        XCTAssertEqual(0, segments.count)
    }

    func testGetMySegmentsAfterLoad() {
        mySegmentsStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = byKeyMySegmentsStorage.getAll()

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))
    }

    func testUpdateSegments() {
        mySegmentsStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = byKeyMySegmentsStorage.getAll()
        byKeyMySegmentsStorage.set(["n1", "n2"])
        let newSegments = byKeyMySegmentsStorage.getAll()
        let savedSegments = mySegmentsStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(2, savedSegments.count)
        XCTAssertTrue(savedSegments.contains("n1"))
        XCTAssertTrue(savedSegments.contains("n2"))

        XCTAssertEqual(2, newSegments.count)
        XCTAssertTrue(newSegments.contains("n1"))
        XCTAssertTrue(newSegments.contains("n2"))
    }

    func testUpdateEmptySegments() {
        mySegmentsStorage.persistedSegments = [userKey : dummySegments]
        mySegmentsStorage.loadLocal(forKey: userKey)
        let segments = byKeyMySegmentsStorage.getAll()
        byKeyMySegmentsStorage.set([String]())
        let newSegments = byKeyMySegmentsStorage.getAll()
        let persistedSegments = mySegmentsStorage.getAll(forKey: userKey)

        XCTAssertEqual(3, segments.count)
        XCTAssertTrue(segments.contains("s1"))
        XCTAssertTrue(segments.contains("s3"))

        XCTAssertEqual(0, newSegments.count)
        XCTAssertEqual(0, persistedSegments.count)
    }

    override func tearDown() {

    }
}
