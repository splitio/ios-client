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
        validator = DefaultApiKeyValidator()
    }
    
    override func tearDown() {
    }
    
    func testValid() {
        XCTAssertNil(validator.validate(apiKey: "key1"))
    }
    
    func testNull() {
        let errorInfo = validator.validate(apiKey: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyKey() {
        let errorInfo = validator.validate(apiKey: "")
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
}
