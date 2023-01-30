//
//  MySegmentsChangeChecker.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

let mySegmentsChangesChecker = DefaultMySegmentsChangesChecker()

class MySegmentsChangesCheckerTest: XCTestCase {

    override func setUp() {
    }

    func testChangesArrived() {

        let old = ["s1", "s2", "s3"]
        let new = ["s1"]
        let result = mySegmentsChangesChecker.mySegmentsHaveChanged(old: old, new: new)

        XCTAssertTrue(result)
    }


    func testNewChangesArrived() {

        let new = ["s1", "s2", "s3"]
        let old = ["s1"]
        let result = mySegmentsChangesChecker.mySegmentsHaveChanged(old: old, new: new)

        XCTAssertTrue(result)
    }

    func testNoChangesArrived() {

        let new = ["s1", "s2", "s3"]
        let old = ["s1", "s2", "s3"]
        let result = mySegmentsChangesChecker.mySegmentsHaveChanged(old: old, new: new)

        XCTAssertFalse(result)
    }

    func testNoChangesArrivedEmpty() {

        let new = [String]()
        let old = [String]()
        let result = mySegmentsChangesChecker.mySegmentsHaveChanged(old: old, new: new)

        XCTAssertFalse(result)
    }

    func testEmptyChangesArrived() {

        let new = [String]()
        let old = ["s1", "s2", "s3"]
        let result = mySegmentsChangesChecker.mySegmentsHaveChanged(old: old, new: new)

        XCTAssertTrue(result)
    }

}
