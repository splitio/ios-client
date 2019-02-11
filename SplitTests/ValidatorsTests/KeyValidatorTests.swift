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
        validator = DefaultKeyValidator()
    }
    
    override func tearDown() {
    }
    
    func testValidMatchingKey() {
        XCTAssertNil(validator.validate(matchingKey: "key1", bucketingKey: nil))
    }
    
    func testValidMatchingAndBucketingKey() {
        XCTAssertNil(validator.validate(matchingKey: "key1", bucketingKey: "bkey1"))
    }
    
    func testNullMatchingKey() {
        let errorInfo = validator.validate(matchingKey: nil, bucketingKey: nil);
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testInvalidEmptyMatchingKey() {
        let errorInfo = validator.validate(matchingKey: "", bucketingKey: nil);
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testInvalidLongMatchingKey() {
        let key = String(repeating: "p", count: 256)
        let errorInfo = validator.validate(matchingKey: key, bucketingKey: nil);
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testInvalidEmptyBucketingKey() {
        let errorInfo = validator.validate(matchingKey: "key1", bucketingKey: "");
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testInvalidLongBucketingKey() {
        let bkey = String(repeating: "p", count: 256)
        let errorInfo = validator.validate(matchingKey: "key1", bucketingKey: bkey);
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
}
