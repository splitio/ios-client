//
//  EventDTOJsonTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 08/05/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class EventDTOJsonTest: XCTestCase {
    func testBasic() {
        let event = try? basicEvent(value: 12.0)

        let jsonEvent = try? Json.dynamicEncodeToJson(event!)
        let testEvent = try? Json.dynamicDecodeFrom(json: jsonEvent!, to: EventDTO.self)

        XCTAssertEqual(event?.key, testEvent?.key)
        XCTAssertEqual(event?.eventTypeId, testEvent?.eventTypeId)
        XCTAssertEqual(event?.trafficTypeName, testEvent?.trafficTypeName)
        XCTAssertEqual(event?.value, testEvent?.value)
    }

    func testPropertiesDecodeEncode() {
        let event = try? basicEvent(value: 12.00001)
        let props: [String: Any] = [
            "valueString": "string",
            "valueTrue": true,
            "valueFalse": false,
            "value0": 0.1,
            "value1": 12.0,
            "value2": 22.1,
            "value3": 1205.06,
            "value4": 22.10001,
            "value5": 2267.1000109,
            "value6": 9900.0000001,
            "value7": 9900.0000001979797979797970100101,
            "value8": 999999999999.999999999999999999999999,
        ]
        event?.properties = props

        let jsonEvent = try? Json.dynamicEncodeToJson(event!)
        let testEvent = try? Json.dynamicDecodeFrom(json: jsonEvent!, to: EventDTO.self)

        let testProps = testEvent?.properties

        XCTAssertEqual(event?.value, testEvent?.value)
        XCTAssertEqual(props["valueString"] as? String, testProps?["valueString"] as? String)
        XCTAssertTrue(testProps?["valueTrue"]! as! Bool)
        XCTAssertFalse(testProps?["valueFalse"]! as! Bool)
        XCTAssertEqual(props["value0"] as? Double, testProps?["value0"] as? Double)
        XCTAssertEqual(props["value1"] as? Double, testProps?["value1"] as? Double)
        XCTAssertEqual(props["value2"] as? Double, testProps?["value2"] as? Double)
        XCTAssertEqual(props["value3"] as? Double, testProps?["value3"] as? Double)
        XCTAssertEqual(props["value4"] as? Double, testProps?["value4"] as? Double)
        XCTAssertEqual(props["value5"] as? Double, testProps?["value5"] as? Double)
        XCTAssertEqual(props["value6"] as? Double, testProps?["value6"] as? Double)
        XCTAssertEqual(props["value7"] as? Double, testProps?["value7"] as? Double)
        XCTAssertEqual(props["value8"] as? Double, testProps?["value8"] as? Double)
    }

    func testProperties() {
        let event = try? basicEvent(value: 12.00001)
        let props: [String: Any] = [
            "valueString": "string",
            "valueTrue": true,
            "valueFalse": false,
            "value0": 0.1,
            "value1": 12.0,
            "value2": 22.1,
            "value3": 1205.06,
            "value4": 22.10001,
            "value5": 2267.1000109,
            "value6": 9900.0000001,
        ]
        event?.properties = props

        let jsonEvent = try? Json.dynamicEncodeToJson(event!)
        let testEvent = try? Json.dynamicDecodeFrom(json: jsonEvent!, to: EventDTO.self)

        let testProps = testEvent?.properties

        XCTAssertEqual("string", testProps?["valueString"] as? String)
        XCTAssertEqual(0.1, testProps?["value0"] as? Double)
        XCTAssertEqual(12.0, testProps?["value1"] as? Double)
        XCTAssertEqual(22.1, testProps?["value2"] as? Double)
        XCTAssertEqual(1205.06, testProps?["value3"] as? Double)
        XCTAssertEqual(22.10001, testProps?["value4"] as? Double)
        XCTAssertEqual(2267.1000109, testProps?["value5"] as? Double)
        XCTAssertEqual(9900.0000001, testProps?["value6"] as? Double)
    }

    func testNonNumber() {
        let event = try? basicEvent(value: 12.00001)
        let props: [String: Any] = [
            "valueString": "string",
            "valueTrue": true,
            "valueFalse": false,
        ]
        event?.properties = props

        let jsonEvent = try? Json.dynamicEncodeToJson(event!)
        let testEvent = try? Json.dynamicDecodeFrom(json: jsonEvent!, to: EventDTO.self)

        let testProps = testEvent?.properties

        XCTAssertEqual("string", testProps?["valueString"] as? String)
        XCTAssertTrue(testProps?["valueTrue"] is Bool)
        XCTAssertTrue(testProps?["valueFalse"] is Bool)
    }

    func testEncode() {
        let jsonEvent = """
        {\"key\":\"thekey\",\"eventTypeId\":\"event1\",\"properties\":{\"value2\":22.1,\"valueString\":\"string\",\"valueFalse\":false,\"value5\":2267.1000109,\"value3\":1205.06,\"value4\":22.10001,\"value1\":12,\"valueTrue\":true,\"value6\":9900.0000001,\"value0\":0.1},\"trafficTypeName\":\"custom\",\"value\":217.00001}
        """

        let testEvent = try? Json.dynamicDecodeFrom(json: jsonEvent, to: EventDTO.self)

        let testProps = testEvent?.properties

        XCTAssertEqual("thekey", testEvent?.key)
        XCTAssertEqual("event1", testEvent?.eventTypeId)
        XCTAssertEqual("custom", testEvent?.trafficTypeName)
        XCTAssertEqual(217.00001, testEvent?.value)
        XCTAssertEqual("string", testProps?["valueString"] as? String)
        XCTAssertEqual(0.1, testProps?["value0"] as? Double)
        XCTAssertEqual(12.0, testProps?["value1"] as? Double)
        XCTAssertEqual(22.1, testProps?["value2"] as? Double)
        XCTAssertEqual(1205.06, testProps?["value3"] as? Double)
        XCTAssertEqual(22.10001, testProps?["value4"] as? Double)
        XCTAssertEqual(2267.1000109, testProps?["value5"] as? Double)
        XCTAssertEqual(9900.0000001, testProps?["value6"] as? Double)
    }

    private func basicEvent(value: Double) throws -> EventDTO {
        let jsonObject: [String: Any] = [
            "key": "thekey",
            "eventTypeId": "event1",
            "trafficTypeName": "custom",
            "value": value,
            "timestamp": 11111111,
        ]

        return try EventDTO(jsonObject: jsonObject)
    }
}
