//
//  AnyValueValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

@testable import Split
import XCTest

class AnyValueValidatorTests: XCTestCase {
    struct TestValue {
        var someProp: String
    }

    var validator: AnyValueValidator!

    override func setUp() {
        validator = DefaultAnyValueValidator()
    }

    override func tearDown() {}

    func testValidPrimitiveValues() {
        XCTAssertTrue(validator.isPrimitiveValue(value: 1))
        XCTAssertTrue(validator.isPrimitiveValue(value: 1.1))
        XCTAssertTrue(validator.isPrimitiveValue(value: "string"))
        XCTAssertTrue(validator.isPrimitiveValue(value: true))
        XCTAssertTrue(validator.isPrimitiveValue(value: false))
        XCTAssertTrue(validator.isPrimitiveValue(value: false))
    }

    func testInvalidPrimitiveValues() {
        XCTAssertFalse(validator.isPrimitiveValue(value: TestValue(someProp: "hi")))
        XCTAssertFalse(validator.isPrimitiveValue(value: ["v1", "v2", "v3"]))
        XCTAssertFalse(validator.isPrimitiveValue(value: ["v1": "v3"]))
        XCTAssertFalse(validator.isPrimitiveValue(value: [1, 2, 3]))
        XCTAssertFalse(validator.isPrimitiveValue(value: [true, false, true]))
    }

    func testValidListValues() {
        XCTAssertTrue(validator.isList(value: ["v1", "v2", "v3"]))
    }

    func testInvalidListValues() {
        XCTAssertFalse(validator.isList(value: 1))
        XCTAssertFalse(validator.isList(value: 1.1))
        XCTAssertFalse(validator.isList(value: "string"))
        XCTAssertFalse(validator.isList(value: true))
        XCTAssertFalse(validator.isList(value: false))
        XCTAssertFalse(validator.isList(value: false))
        XCTAssertFalse(validator.isList(value: TestValue(someProp: "hi")))
        // These list values return false in a evaluation
        XCTAssertFalse(validator.isList(value: [1, 2, 3]))
        XCTAssertFalse(validator.isList(value: [true, false, true]))
        XCTAssertFalse(validator.isList(value: Set(["a", "b", "c"])))
    }
}
