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
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testNull() {
        let name = SplitValidatable(name: nil)
        XCTAssertFalse(name.isValid(validator: validator), "name should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testEmptyName() {
        let name = SplitValidatable(name: "")
        XCTAssertFalse(name.isValid(validator: validator), "name should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testLeadingSpaces() {
        let name = SplitValidatable(name: " split")
        XCTAssertTrue(name.isValid(validator: validator), "name should be valid")
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 1)
        XCTAssertEqual(validator.warnings[0], SplitNameValidationWarning.nameWasTrimmed)
    }
    
    func testTrailingSpaces() {
        let name = SplitValidatable(name: "split ")
        XCTAssertTrue(name.isValid(validator: validator), "name should be valid")
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 1)
        XCTAssertEqual(validator.warnings[0], SplitNameValidationWarning.nameWasTrimmed)
    }
}
