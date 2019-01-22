//
//  TrackTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class EventBuilderTests: XCTestCase {

    var builder: EventBuilder!
    var typeNameHelper: EventTypeNameHelper!
    
    override func setUp() {
        builder = EventBuilder()
        typeNameHelper = EventTypeNameHelper()
    }

    override func tearDown() {
        
    }

    func testAllValuesFilled() {
        var event: EventDTO? = nil
        do {
            event = try  builder
                .setTrafficType("custom")
                .setKey("key1")
                .setType("type1")
                .setValue(1.0).build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should not be null")
        XCTAssertEqual(event?.eventTypeId, "type1", "Type value")
        XCTAssertEqual(event?.key, "key1", "Key value")
        XCTAssertEqual(event?.trafficTypeName, "custom", "Traffic type value")
        XCTAssertEqual(event?.value, 1.0, "Value")
        XCTAssertNotNil(event?.timestamp, "Timestamp")
    }
    
    func testEventValueNull() {
        var event: EventDTO? = nil
        do {
            event = try builder.setTrafficType("custom")
                .setKey("key1")
                .setType("type1")
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should not be null")
        XCTAssertEqual(event?.eventTypeId, "type1", "Type value")
        XCTAssertEqual(event?.key, "key1", "Key value")
        XCTAssertEqual(event?.trafficTypeName, "custom", "Traffic type value")
        XCTAssertNil(event?.value, "Value")
        XCTAssertNotNil(event?.timestamp, "Timestamp")
    }
    
    func testNullTrafficType() {
        var trafficTypeErrorOccurs = false
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setType("type1")
                .build()
        } catch EventValidationError.nullTrafficType {
            trafficTypeErrorOccurs = true
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
        XCTAssertTrue(trafficTypeErrorOccurs, "Traffic type should be null")
        
    }
    
    func testNullMatchingKey() {
        var keyErrorOccurs = false
        
        
        var event: EventDTO? = nil
        do {
            event = try builder
                .setType("type1")
                .setTrafficType("custom")
                .build()
        } catch EventValidationError.nullMatchingKey {
            keyErrorOccurs = true
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
        XCTAssertTrue(keyErrorOccurs, "keyErrorOccurs should be null")
    }
    
    func testNullType() {
        var typeErrorOccurs = false
        
        
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .build()
        } catch EventValidationError.nullType {
            typeErrorOccurs = true
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
        XCTAssertTrue(typeErrorOccurs, "Type should be null")
    }
    
    func testValidAllValidCharsTypeName() {
        let typeName = typeNameHelper.validAllValidChars
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should be null")
        XCTAssertEqual(event?.eventTypeId, typeName, "Name should be equal")
    }
    
    func testNumberStartValidTypeName() {
        let typeName = typeNameHelper.validStartNumber
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should not be null")
        XCTAssertEqual(event?.eventTypeId, typeName, "Name should be equal")
    }
    
    func testHypenStartInvalidTypeName() {
        let typeName = typeNameHelper.invalidHypenStart
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }
    
    func testUndercoreStartInvalidTypeName() {
        let typeName = typeNameHelper.invalidUndercoreStart
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }
    
    func testInvalidCharsTypeName() {
        let typeName = typeNameHelper.invalidChars
        var event: EventDTO? = nil
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }
    
    func testUppercaseCharsInTrafficType() {
        var event: EventDTO? = nil
        var event1: EventDTO? = nil
        var event2: EventDTO? = nil
        
        do {
            event = try builder
                .setKey("key1")
                .setTrafficType("Custom")
                .setType("typeName")
                .build()
        } catch {
        }
        
        do {
            event1 = try builder
                .setTrafficType("custoM")
                .build()
        } catch {
        }
        
        do {
            event2 = try builder
                .setTrafficType("cUSTOm")
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should not be null")
        XCTAssertEqual(event?.trafficTypeName, "custom")
        
        XCTAssertNotNil(event1, "Event should not be null")
        XCTAssertEqual(event1?.trafficTypeName, "custom")
        
        XCTAssertNotNil(event2, "Event should not be null")
        XCTAssertEqual(event2?.trafficTypeName, "custom")
    }

}
