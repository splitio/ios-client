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
        validator = DefaultSplitChangeValidator()
    }
    
    override func tearDown() {
    }
    
    func testValid() {
        let change = SplitChange()
        change.splits = []
        change.since = 1111
        change.till = 2222
        XCTAssertNil(validator.validate(change))
    }
    
    func testAllNull() {
        XCTAssertNotNil(validator.validate(SplitChange()))
    }
    
    func testNullSplits() {
        let change = SplitChange()
        change.splits = nil
        change.since = 1111
        change.till = 2222
        XCTAssertNotNil(validator.validate(change))
    }
    
    func testNullSince() {
        let change = SplitChange()
        change.splits = []
        change.since = nil
        change.till = 2222
        XCTAssertNotNil(validator.validate(change))
    }
    
    func testNullTill() {
        let change = SplitChange()
        change.splits = []
        change.since = 1111
        change.till = nil
        XCTAssertNotNil(validator.validate(change))
    }
}
