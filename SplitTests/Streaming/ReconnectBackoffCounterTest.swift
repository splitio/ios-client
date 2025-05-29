//
//  ReconnectBackoffCounterTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ReconnectBackoffCounterTest: XCTestCase {
    override func setUp() {}

    func testBase1() {
        let results: [Double] = [1, 2, 4, 8, 30, 1]
        testWithBase(base: 1, results: results)
    }

    func testBase2() {
        let results: [Double] = [1, 4, 16, 64, 256, 1]
        testWithBase(base: 2, results: results)
    }

    func testBase3() {
        let results: [Double] = [1, 6, 36, 216, 1]
        testWithBase(base: 3, results: results)
    }

    func testBase8() {
        let results: [Double] = [1, 16, 256, 1800, 1]
        testWithBase(base: 8, results: results)
    }

    private func testWithBase(base: Int, results: [Double]) {
        let counter = DefaultReconnectBackoffCounter(backoffBase: base)
        let v1 = counter.getNextRetryTime()
        let v2 = counter.getNextRetryTime()
        let v3 = counter.getNextRetryTime()
        let v4 = counter.getNextRetryTime()

        for _ in 0 ..< 2000 {
            _ = counter.getNextRetryTime()
        }
        let vMax = counter.getNextRetryTime()
        counter.resetCounter()
        let vReset = counter.getNextRetryTime()

        XCTAssertEqual(results[0], v1)
        XCTAssertEqual(results[1], v2)
        XCTAssertEqual(results[2], v3)
        XCTAssertEqual(results[3], v4)
        XCTAssertEqual(1800, vMax)
        XCTAssertEqual(1, vReset)
    }

    override func tearDown() {}
}
