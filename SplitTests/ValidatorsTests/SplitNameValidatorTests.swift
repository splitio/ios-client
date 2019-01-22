//
//  SplitNameValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitNameValidatorTests: XCTestCase {
    
    var validator: SplitNameValidator!
    
    override func setUp() {
        validator = SplitNameValidator(tag: "SplitNameValidatorTests")
    }
    
    override func tearDown() {
    }
    
    func testValid() {
        let name = SplitValidatable(name: "name1")
        XCTAssertTrue(name.isValid(validator: validator), "name should be valid")
    }
    
    func testNull() {
        let name = SplitValidatable(name: nil)
        XCTAssertFalse(name.isValid(validator: validator), "name should not be valid")
    }
    
    func testEmptyname() {
        let name = SplitValidatable(name: "")
        XCTAssertFalse(name.isValid(validator: validator), "name should not be valid")
    }
}
