//
//  KeyValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class KeyValidatorTests: XCTestCase {
    
    var validator: KeyValidator!
    
    override func setUp() {
        validator = KeyValidator(tag: "KeyValidatorTests")
    }
    
    override func tearDown() {
    }
    
    func testValidMatchingKey() {
        let key = KeyValidatable(matchingKey: "key1")
        XCTAssertTrue(key.isValid(validator: validator), "Key should be valid")
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testValidMatchingAndBucketingKey() {
        let key = KeyValidatable(matchingKey: "key1", bucketingKey: "bkey1")
        XCTAssertTrue(key.isValid(validator: validator), "Key should be valid")
        XCTAssertNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testNullMatchingKey() {
        let key = KeyValidatable(matchingKey: nil)
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.error, KeyValidationError.nullMatchingKey)
        XCTAssertEqual(validator.warnings.count, 0)
        
    }
    
    func testInvalidEmptyMatchingKey() {
        let key = KeyValidatable(matchingKey: "")
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.error, KeyValidationError.emptyMatchingKey)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testInvalidLongMatchingKey() {
        let key = KeyValidatable(matchingKey: String(repeating: "p", count: 256))
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertEqual(validator.error, KeyValidationError.longMatchingKey)
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testInvalidEmptyBucketingKey() {
        let key = KeyValidatable(matchingKey: "key1", bucketingKey: "")
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.error, KeyValidationError.emptyBucketingkey)
        XCTAssertEqual(validator.warnings.count, 0)
    }
    
    func testInvalidLongBucketingKey() {
        let key = KeyValidatable(matchingKey: "key1", bucketingKey: String(repeating: "p", count: 256))
        XCTAssertFalse(key.isValid(validator: validator), "Key should not be valid")
        XCTAssertNotNil(validator.error)
        XCTAssertEqual(validator.error, KeyValidationError.longBucketingKey)
        XCTAssertEqual(validator.warnings.count, 0)
    }
}
