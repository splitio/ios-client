//
//  LatencyCounterTestsI.swift
//  SplitTests
//
//  Created by Javier on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest

@testable import Split

class LatencyCounterTests: XCTestCase {
    var counter = LatencyCounter()
    let firstBucketIndex = 0
    let lastBucketIndex = 22

    override func setUp() {
        super.setUp()
        counter.resetCounters()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInvalidIndex() {
        XCTAssertTrue(counter.count(for: -1) == -1, "Index bellow min")
        XCTAssertTrue(counter.count(for: 50) == -1, "Index bigger than max")
    }

    func testFirstBucket() {
        counter.addLatency(microseconds: 0)
        counter.addLatency(microseconds: 1000)
        counter.addLatency(microseconds: 1499)
        counter.addLatency(microseconds: 1500) // Not in first bucket
        XCTAssertTrue(counter.count(for: firstBucketIndex) == 3, "First bucket count")
    }

    func testLastBucket() {
        counter.addLatency(microseconds: 7481827) // Not in last bucket
        counter.addLatency(microseconds: 7481828)
        counter.addLatency(microseconds: 7481838)
        counter.addLatency(microseconds: 8481828)
        XCTAssertTrue(counter.count(for: lastBucketIndex) == 3, "Last bucket count")
    }

    func testAllBuckets() {
        let latencies: [Int64] = [
            1000, 1500, 2250, 3375, 5063,
            7594, 11391, 17086, 25629, 38443,
            57665, 86498, 129746, 194620, 291929,
            437894, 656841, 985261, 1477892, 2216838,
            3325257, 4987885, 7481828,
        ]

        for latency in latencies {
            counter.addLatency(microseconds: latency)
        }

        for index in 0 ... 22 {
            XCTAssertTrue(counter.count(for: index) == 1, "All bucket count - Index: \(index)")
        }
    }
}
