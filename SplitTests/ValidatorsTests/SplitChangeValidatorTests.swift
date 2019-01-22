//
//  SplitChangeValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitChangeValidatorTests: XCTestCase {
    
    var validator: SplitChangeValidator!
    
    override func setUp() {
        validator = SplitChangeValidator()
    }
    
    override func tearDown() {
    }
    
    func testValid() {
        let change = SplitChange()
        change.splits = []
        change.since = 1111
        change.till = 2222
        XCTAssertTrue(SplitChangeValidatable(splitChange: change).isValid(validator: validator), "Change should be valid")
    }
    
    func testAllNull() {
        XCTAssertFalse(SplitChangeValidatable(splitChange: SplitChange()).isValid(validator: validator), "Change should be valid")
    }
    
    func testNullSplits() {
        let change = SplitChange()
        change.splits = nil
        change.since = 1111
        change.till = 2222
        XCTAssertFalse(SplitChangeValidatable(splitChange: change).isValid(validator: validator), "Change should be valid")
    }
    
    func testNullSince() {
        let change = SplitChange()
        change.splits = []
        change.since = nil
        change.till = 2222
        XCTAssertFalse(SplitChangeValidatable(splitChange: change).isValid(validator: validator), "Change should be valid")
    }
    
    func testNullTill() {
        let change = SplitChange()
        change.splits = []
        change.since = 1111
        change.till = nil
        XCTAssertFalse(SplitChangeValidatable(splitChange: change).isValid(validator: validator), "Change should be valid")
    }
}
