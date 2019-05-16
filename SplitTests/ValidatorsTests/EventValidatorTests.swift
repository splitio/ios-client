//
//  EventValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class EventValidatorTests: XCTestCase {
    
    var validator: EventValidator!
    
    override func setUp() {
        validator = DefaultEventValidator()
    }
    
    override func tearDown() {
    }
    
    func testValidEventAllValues() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: 1.0, properties: nil))
    }

    func testValidEventNullValue() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil))
    }
    
    func testNullKey() {
        let errorInfo = validator.validate(key: nil, trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyKey() {
        let errorInfo = validator.validate(key: "", trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testLongKey() {
        let key = String(repeating: "p", count: 300)
        let errorInfo = validator.validate(key: key, trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testNullType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nil, value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: "", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testTypeName() {
        
        let nameHelper = EventTypeNameHelper()
        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validAllValidChars, value: nil, properties: nil)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validStartNumber, value: nil, properties: nil)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidChars, value: nil, properties: nil)
        let errorInfo4 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidUndercoreStart, value: nil, properties: nil)
        let errorInfo5 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidHypenStart, value: nil, properties: nil)
        
        XCTAssertNil(errorInfo1)
        XCTAssertNil(errorInfo2)
        
        XCTAssertNotNil(errorInfo3)
        XCTAssertNotNil(errorInfo3?.error)
        XCTAssertNotNil(errorInfo3?.errorMessage)
        XCTAssertEqual(errorInfo3?.warnings.count, 0)
        
        XCTAssertNotNil(errorInfo4)
        XCTAssertNotNil(errorInfo4?.error)
        XCTAssertNotNil(errorInfo4?.errorMessage)
        XCTAssertEqual(errorInfo4?.warnings.count, 0)
        
        XCTAssertNotNil(errorInfo5)
        XCTAssertNotNil(errorInfo5?.error)
        XCTAssertNotNil(errorInfo5?.errorMessage)
        XCTAssertEqual(errorInfo5?.warnings.count, 0)
        
    }
    
    func testNullTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: nil, eventTypeId: "type1", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "", eventTypeId: "type1", value: nil, properties: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testUppercaseCharsInTrafficType() {
        
        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "Custom", eventTypeId: "type1", value: nil, properties: nil)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "cUSTom", eventTypeId: "type1", value: nil, properties: nil)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custoM", eventTypeId: "type1", value: nil, properties: nil)
        
        XCTAssertNotNil(errorInfo1)
        XCTAssertNil(errorInfo1?.error)
        XCTAssertNil(errorInfo1?.errorMessage)
        XCTAssertEqual(errorInfo1?.warnings.count, 1)
        XCTAssertTrue(errorInfo1?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
        
        XCTAssertNotNil(errorInfo2)
        XCTAssertNil(errorInfo2?.error)
        XCTAssertNil(errorInfo2?.errorMessage)
        XCTAssertEqual(errorInfo2?.warnings.count, 1)
        XCTAssertTrue(errorInfo2?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
        
        XCTAssertNotNil(errorInfo3)
        XCTAssertNil(errorInfo3?.error)
        XCTAssertNil(errorInfo3?.errorMessage)
        XCTAssertEqual(errorInfo3?.warnings.count, 1)
        XCTAssertTrue(errorInfo3?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
        
    }
}
