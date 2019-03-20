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
        let split1 = newSplit(trafficType: "custom")
        let split2 = newSplit(trafficType: "other")
        let split3 = newSplit(trafficType: "archivedtraffictype", status: .Archived)
        let splits = [split1, split2, split3]
        let trafficTypeChache = InMemoryTrafficTypesCache(splits: splits)
        validator = DefaultEventValidator(trafficTypesCache: trafficTypeChache)
    }
    
    override func tearDown() {
    }
    
    func testValidEventAllValues() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: 1.0))
    }

    func testValidEventNullValue() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: nil))
    }
    
    func testNullKey() {
        let errorInfo = validator.validate(key: nil, trafficTypeName: "custom", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyKey() {
        let errorInfo = validator.validate(key: "", trafficTypeName: "custom", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testLongKey() {
        let key = String(repeating: "p", count: 300)
        let errorInfo = validator.validate(key: key, trafficTypeName: "custom", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testNullType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nil, value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: "", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testTypeName() {
        
        let nameHelper = EventTypeNameHelper()
        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validAllValidChars, value: nil)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validStartNumber, value: nil)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidChars, value: nil)
        let errorInfo4 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidUndercoreStart, value: nil)
        let errorInfo5 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidHypenStart, value: nil)
        
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
        let errorInfo = validator.validate(key: "key1", trafficTypeName: nil, eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testEmptyTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNotNil(errorInfo?.error)
        XCTAssertNotNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }
    
    func testUppercaseCharsInTrafficType() {
        
        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "Custom", eventTypeId: "type1", value: nil)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "cUSTom", eventTypeId: "type1", value: nil)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custoM", eventTypeId: "type1", value: nil)
        
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
    
    func testNoChachedServerTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "nocached", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeWithoutSplitInEnvironment) ?? false)
    }
    
    func testNoChachedServerAndUppercasedTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "noCached", eventTypeId: "type1", value: nil)
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 2)
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeWithoutSplitInEnvironment) ?? false)
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
    }
    
    private func newSplit(trafficType: String, status: Status = .Active) -> Split {
        let split = Split()
        split.name = UUID().uuidString
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }
}
