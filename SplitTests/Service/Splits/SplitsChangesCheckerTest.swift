//
//  SplitsChangesCheckerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SplitsChangesCheckerTest: XCTestCase {
    let splitsChangesChecker = DefaultSplitsChangesChecker()

    override func setUp() {}

    func testSplitsChangesArrived() {
        let result = splitsChangesChecker.splitsHaveChanged(oldChangeNumber: 100, newChangeNumber: 101)

        XCTAssertTrue(result)
    }

    func testSplitsNoChangesMinorChangeNumber() {
        let result = splitsChangesChecker.splitsHaveChanged(oldChangeNumber: 101, newChangeNumber: 100)

        XCTAssertFalse(result)
    }

    func testSplitsNoChangesEqualChangeNumber() {
        let result = splitsChangesChecker.splitsHaveChanged(oldChangeNumber: 100, newChangeNumber: 100)

        XCTAssertFalse(result)
    }

    override func tearDown() {}
}
