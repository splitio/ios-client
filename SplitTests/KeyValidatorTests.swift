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
    
    func testValidKey() {
        let key = KeyValidatable(matchingKey: "key1")
        XCTAssertTrue(validator.isValidEntity(key), "Key should be valid")
    }
    
    func testInvalidEmptyKey() {
        let key = KeyValidatable(matchingKey: "")
        XCTAssertFalse(validator.isValidEntity(key), "Key should not be valid")
    }
    
    func testInvalidLongKey() {
        let key = KeyValidatable(matchingKey: String(repeating: "p", count: 256))
        XCTAssertFalse(validator.isValidEntity(key), "Key should not be valid")
    }
}
