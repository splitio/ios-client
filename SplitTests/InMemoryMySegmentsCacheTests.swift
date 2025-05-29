//
//  InMemoryMySegmentsCacheTests.swift
//  Split
//
//  Created by Brian Sztamfater on 5/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class InMemoryMySegmentsCacheTests: XCTestCase {
    var mySegmentsCache: InMemoryMySegmentsCache!

    override func setUp() {
        mySegmentsCache = InMemoryMySegmentsCache()
        mySegmentsCache.addSegments(segmentNames: ["segment1", "segment2", "segment3"], key: "some_user_key")
    }

    override func tearDown() {}

    func testAddMySegments() {
        let segments = mySegmentsCache.getSegments(key: "some_user_key")
        XCTAssertNotNil(segments, "Segments for this key should not be nil")
        XCTAssertTrue(segments!.count == 3, "Should be 3 segments")
    }

    func testIsInSegment() {
        XCTAssertTrue(
            mySegmentsCache.isInSegment(segmentName: "segment1", key: "some_user_key"),
            "Segment1 should be in cache")
        XCTAssertFalse(
            mySegmentsCache.isInSegment(segmentName: "segment4", key: "some_user_key"),
            "Segment4 should not be in cache")
        XCTAssertTrue(
            mySegmentsCache.isInSegment(segmentName: "segment2", key: "some_user_key"),
            "Segment2 should be in cache")
    }

    func testRemoveSegment() {
        mySegmentsCache.removeSegments()
        XCTAssertFalse(
            mySegmentsCache.isInSegment(segmentName: "segment2", key: "some_user_key"),
            "Segment2 should be in cache")
    }

    func testClearCache() {
        mySegmentsCache.clear()
        XCTAssertTrue(mySegmentsCache.getSegments()!.isEmpty, "Segment count should be 0")
    }
}
