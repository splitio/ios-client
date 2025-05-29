//
//  ComputeProcessCountTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ComputeProcessTest: XCTestCase {
    // This test should work as expected from iPhone 5+

    func testOneLessThanMinProcess() {
        let count = ThreadUtils.processCount(totalTaskCount: 9, minTaskPerThread: 10)

        XCTAssertEqual(1, count)
    }

    func testOneProcessEqualsMin() {
        let count = ThreadUtils.processCount(totalTaskCount: 10, minTaskPerThread: 10)

        XCTAssertEqual(1, count)
    }

    func testTwoProcess() {
        let count = ThreadUtils.processCount(totalTaskCount: 11, minTaskPerThread: 10)

        XCTAssertEqual(2, count)
    }

    func testTwoProcessEdge() {
        let count = ThreadUtils.processCount(totalTaskCount: 20, minTaskPerThread: 10)

        XCTAssertEqual(2, count)
    }

    // if available more than 2 cpu
    func testMultiProcess() {
        let count = ThreadUtils.processCount(totalTaskCount: 500, minTaskPerThread: 10)

        XCTAssertTrue(count >= 2)
    }

    override func tearDown() {}
}
