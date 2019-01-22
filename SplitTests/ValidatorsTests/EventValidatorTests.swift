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
        validator = EventValidator(tag: "EventValidatorTests")
    }
    
    override func tearDown() {
    }
    
    func testValidEventAllValues() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = "traffic1"
        event.key = "pepe"
        event.value = 1.0
        XCTAssertTrue(event.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }

    func testValidEventNullValue() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = "traffic1"
        event.key = "pepe"
        event.value = nil
        XCTAssertTrue(event.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testNullKey() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = "traffic1"
        event.key = nil
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.nullMatchingKey, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testEmptyKey() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = "traffic1"
        event.key = ""
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.emptyMatchingKey, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testLongKey() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = "traffic1"
        event.key = String(repeating: "p", count: 300)
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.longMatchingKey, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testNullType() {
        var event = EventValidatable()
        event.eventTypeId = nil
        event.trafficTypeName = "traffic1"
        event.key = "key1"
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.nullType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testEmptyType() {
        var event = EventValidatable()
        event.eventTypeId = ""
        event.trafficTypeName = "traffic1"
        event.key = "key1"
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.emptyType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testTypeName() {
        func newEvent() -> EventValidatable {
            var event = EventValidatable()
            event.trafficTypeName = "traffic1"
            event.key = "key1"
            return event
        }
        let nameHelper = EventTypeNameHelper()
        var event1 = newEvent()
        var event2 = newEvent()
        var event3 = newEvent()
        var event4 = newEvent()
        var event5 = newEvent()
        event1.eventTypeId = nameHelper.validAllValidChars
        event2.eventTypeId = nameHelper.validStartNumber
        event3.eventTypeId = nameHelper.invalidChars
        event4.eventTypeId = nameHelper.invalidUndercoreStart
        event5.eventTypeId = nameHelper.invalidHypenStart
        
        XCTAssertTrue(event1.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
        
        XCTAssertTrue(event2.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
        
        XCTAssertFalse(event3.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should not be nil")
        XCTAssertEqual(validator.error, EventValidationError.invalidType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
        
        XCTAssertFalse(event4.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should not be nil")
        XCTAssertEqual(validator.error, EventValidationError.invalidType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
        
        XCTAssertFalse(event5.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should not be nil")
        XCTAssertEqual(validator.error, EventValidationError.invalidType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testNullTrafficType() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = nil
        event.key = "key1"
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.nullTrafficType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testEmptyTrafficType() {
        var event = EventValidatable()
        event.eventTypeId = "type1"
        event.trafficTypeName = ""
        event.key = "key1"
        XCTAssertFalse(event.isValid(validator: validator), "Event should not be valid")
        XCTAssertNotNil(validator.error, "Error should be not nil")
        XCTAssertEqual(validator.error, EventValidationError.emptyTrafficType, "Error ok")
        XCTAssertEqual(validator.warnings.count, 0, "Count should be 0")
    }
    
    func testUppercaseCharsInTrafficType() {
        
        func newEvent() -> EventValidatable {
            var event = EventValidatable()
            event.eventTypeId = "type1"
            event.key = "key1"
            return event
        }
        
        var event1 = newEvent()
        var event2 = newEvent()
        var event3 = newEvent()
        event1.trafficTypeName = "Custom"
        event2.trafficTypeName = "cUSTom"
        event3.trafficTypeName = "custoM"
        
        XCTAssertTrue(event1.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 1, "Count should be 1")
        
        if validator.warnings.count > 0 {
            XCTAssertEqual(validator.warnings[0], EventValidationWarning.uppercaseTrafficType, "Warning ok")
        }
        
        XCTAssertTrue(event2.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 1, "Count should be 1")
        if validator.warnings.count > 0 {
            XCTAssertEqual(validator.warnings[0], EventValidationWarning.uppercaseTrafficType, "Warning ok")
        }
        
        XCTAssertTrue(event2.isValid(validator: validator), "Event should be valid")
        XCTAssertNil(validator.error, "Error should be nil")
        XCTAssertEqual(validator.warnings.count, 1, "Count should be 1")
        if validator.warnings.count > 0 {
            XCTAssertEqual(validator.warnings[0], EventValidationWarning.uppercaseTrafficType, "Warning ok")
        }
    }
}
