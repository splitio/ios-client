//
//  RecorderFlusherCheckerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class RecorderFlusherCheckerTests: XCTestCase {
    var checker: RecorderFlushChecker!
    let maxBytes = 1000
    let maxCount = 100

    override func setUp() {
        checker = DefaultRecorderFlushChecker(maxQueueSize: maxCount, maxQueueSizeInBytes: maxBytes)
    }

    func testBytesLimit() {
        let r1 = checker.checkIfFlushIsNeeded(sizeInBytes: 800)
        let r2 = checker.checkIfFlushIsNeeded(sizeInBytes: 100)
        let r3 = checker.checkIfFlushIsNeeded(sizeInBytes: 100)

        XCTAssertFalse(r1)
        XCTAssertFalse(r2)
        XCTAssertTrue(r3)
    }

    func testCountLimit() {
        for _ in 1 ..< (maxCount - 2) {
            _ = checker.checkIfFlushIsNeeded(sizeInBytes: 1)
        }

        let r1 = checker.checkIfFlushIsNeeded(sizeInBytes: 1)
        let r2 = checker.checkIfFlushIsNeeded(sizeInBytes: 1)
        let r3 = checker.checkIfFlushIsNeeded(sizeInBytes: 1)

        XCTAssertFalse(r1)
        XCTAssertFalse(r2)
        XCTAssertTrue(r3)
    }

    override func tearDown() {}
}
