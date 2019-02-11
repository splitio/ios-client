//
//  SplitNameValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitValidatorTests: XCTestCase {
    
    var validator: SplitValidator!
    
    override func setUp() {
        validator = DefaultSplitValidator()
    }
    
    override func tearDown() {
    }
    
    func testValidName() {
        XCTAssertNil(validator.validate(name: "name1"))
    }
    
    func testNullName() {
        let errorInfo = validator.validate(name: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyName() {
        let errorInfo = validator.validate(name: "")
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testLeadingSpacesName() {
        let errorInfo = validator.validate(name: " split")
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.splitNameShouldBeTrimmed) ?? false)
    }
    
    func testTrailingSpacesName() {
        let errorInfo = validator.validate(name: "split ")
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.splitNameShouldBeTrimmed) ?? false)
    }
}
