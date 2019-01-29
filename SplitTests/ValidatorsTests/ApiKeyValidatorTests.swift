//
//  ApiKeyValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class ApiKeyValidatorTests: XCTestCase {
    
    var validator: ApiKeyValidator!
    
    override func setUp() {
        validator = ApiKeyValidator(tag: "ApiKeyValidatorTests")
    }
    
    override func tearDown() {
    }
    
    func testValid() {
        let key = ApiKeyValidatable(apiKey: "key1")
        XCTAssertTrue(key.isValid(validator: validator), "Key should be valid")
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testNull() {
        let key = ApiKeyValidatable(apiKey: nil)
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testEmptyKey() {
        let key = ApiKeyValidatable(apiKey: "")
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
}
