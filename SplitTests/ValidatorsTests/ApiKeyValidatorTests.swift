//
//  ApiKeyValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class ApiKeyValidatorTests: XCTestCase {
    var validator: ApiKeyValidator!

    override func setUp() {
        validator = DefaultApiKeyValidator()
    }

    override func tearDown() {}

    func testValid() {
        XCTAssertNil(validator.validate(apiKey: "key1"))
    }

    func testNull() {
        let errorInfo = validator.validate(apiKey: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed a null api_key, the api_key must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testEmptyKey() {
        let errorInfo = validator.validate(apiKey: "")
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed an empty api_key, api_key must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
}
