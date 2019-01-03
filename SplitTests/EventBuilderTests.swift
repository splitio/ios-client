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
    
    override func setUp() {
        builder = EventBuilder()
    }

    override func tearDown() {
        
    }

    func testAllValuesFilled() {
        var event: EventDTO? = nil
        do {
            event = try  builder
                .setTrafficType("custom")
                .setMatchingKey("key1")
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
                .setMatchingKey("key1")
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
                .setMatchingKey("key1")
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
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .build()
        } catch EventValidationError.nullType {
            typeErrorOccurs = true
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
        XCTAssertTrue(typeErrorOccurs, "Type should be null")
    }
    
    func testValidTypeName() {
        let typeName = "Abcdefghij:klmnopkrstuvwxyz_-12345.6789:"
        var event: EventDTO? = nil
        do {
            event = try builder
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should be null")
        XCTAssertEqual(event?.eventTypeId, typeName, "Name should be equal")
    }
    
    func testNumberStartValidTypeName() {
        let typeName = "1Abcdefghijklmnopkrstuvwxyz_-12345.6789:"
        var event: EventDTO? = nil
        do {
            event = try builder
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNotNil(event, "Event should not be null")
        XCTAssertEqual(event?.eventTypeId, typeName, "Name should be equal")
    }
    
    func testHypenStartInvalidTypeName() {
        let typeName = "-1Abcdefghijklmnopkrstuvwxyz_-123456789:"
        var event: EventDTO? = nil
        do {
            event = try builder
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }
    
    func testUndercoreStartInvalidTypeName() {
        let typeName = "_1Abcdefghijklmnopkrstuvwxyz_-123456789:"
        var event: EventDTO? = nil
        do {
            event = try builder
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }
    
    func testInvalidCharsTypeName() {
        let typeName = "Abcd,;][}{efghijklmnopkrstuvwxyz_-123456789:"
        var event: EventDTO? = nil
        do {
            event = try builder
                .setMatchingKey("key1")
                .setTrafficType("custom")
                .setType(typeName)
                .build()
        } catch {
        }
        
        XCTAssertNil(event, "Event should be null")
    }

}
