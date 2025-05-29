//
//  PropertyValidatorTest.swift
//  SplitTests
//
//  Created on 2025-03-26.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class PropertyValidatorTest: XCTestCase {
    var propertyValidator: DefaultPropertyValidator!
    var anyValueValidator: AnyValueValidatorStub!
    var validationLogger: ValidationMessageLoggerStub!

    override func setUp() {
        anyValueValidator = AnyValueValidatorStub()
        validationLogger = ValidationMessageLoggerStub()
        propertyValidator = DefaultPropertyValidator(
            anyValueValidator: anyValueValidator,
            validationLogger: validationLogger)
    }

    func testValidateNilProperties() {
        let result = propertyValidator.validate(properties: nil, initialSizeInBytes: 100, validationTag: "test")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.validatedProperties)
        XCTAssertEqual(result.sizeInBytes, 100)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateEmptyProperties() {
        let result = propertyValidator.validate(properties: [:], initialSizeInBytes: 100, validationTag: "test")

        XCTAssertTrue(result.isValid)
        XCTAssertNotNil(result.validatedProperties)
        XCTAssertEqual(result.validatedProperties?.count, 0)
        XCTAssertEqual(result.sizeInBytes, 100)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateValidProperties() {
        let testProperties = ["key1": "value1", "key2": 123, "key3": true] as [String: Any]
        let result = propertyValidator.validate(
            properties: testProperties,
            initialSizeInBytes: 100,
            validationTag: "test")

        XCTAssertTrue(result.isValid)
        XCTAssertNotNil(result.validatedProperties)
        XCTAssertEqual(result.validatedProperties?.count, 3)
        XCTAssertGreaterThan(result.sizeInBytes, 100)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateTooManyProperties() {
        var testProperties = [String: Any]()
        for i in 0 ... 301 {
            testProperties["\(i)"] = "\(i)"
        }

        let result = propertyValidator.validate(
            properties: testProperties,
            initialSizeInBytes: 0,
            validationTag: "test")

        // Validation should still pass, but a warning should be logged
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(validationLogger.hasWarnings)

        // Check that the warning message contains the expected text
        XCTAssertEqual(validationLogger.warnings.count, 1)
        XCTAssertTrue(validationLogger.warnings[0].message.contains("more than 300 properties"))
    }

    func testValidatePropertiesTooLarge() {
        let maxBytes = ValidationConfig.default.maximumEventPropertyBytes
        let initialSize = 100
        let propertySize = maxBytes - initialSize + 1

        let largeValue = String(repeating: "a", count: propertySize)
        let testProperties = ["largeKey": largeValue]

        let result = propertyValidator.validate(
            properties: testProperties,
            initialSizeInBytes: initialSize,
            validationTag: "test")

        // Validation should fail due to size limit
        XCTAssertFalse(result.isValid)
        XCTAssertNil(result.validatedProperties)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertTrue(result.errorMessage?.contains("maximum size allowed") ?? false)
        XCTAssertTrue(validationLogger.hasError)
    }
}
