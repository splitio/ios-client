//
//  EventStreamParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventStreamParserTest: XCTestCase {
    let parser = EventStreamParser()

    override func setUp() {}

    func testParseErrorMessage() {
        let values = parser.parse(streamChunk: "id:theid")

        XCTAssertEqual(1, values.count)
        XCTAssertEqual(values["id"], "theid")
    }

    func testParseColon() {
        let values = parser.parse(streamChunk: ":")

        XCTAssertEqual(0, values.count)
    }

    func testParseEmptyLineNoEnd() {
        let values = parser.parse(streamChunk: "")

        XCTAssertEqual(0, values.count)
    }

    func testParseEnd() {
        let msg = "id:theid\nevent:message\ndata:{\"c1\":1}"
        let values = parser.parse(streamChunk: msg)

        XCTAssertEqual(3, values.count)
        XCTAssertEqual("theid", values["id"])
        XCTAssertEqual("message", values["event"])
        XCTAssertEqual("{\"c1\":1}", values["data"])
    }

    func testParseTwoColon() {
        let values = parser.parse(streamChunk: "id:value:value")

        XCTAssertEqual(1, values.count)
        XCTAssertEqual("value:value", values["id"])
    }

    func testParseNoColon() {
        let values = parser.parse(streamChunk: "fieldName")

        XCTAssertEqual(1, values.count)
        XCTAssertEqual("", values["fieldName"])
    }

    func testParseNoFieldName() {
        let values = parser.parse(streamChunk: ":fieldName")

        XCTAssertEqual(0, values.count)
    }

    func testParseKeepAlive() {
        let values = parser.parse(streamChunk: "keepalive:")

        XCTAssertEqual(1, values.count)
        XCTAssertEqual("", values["keepalive"])
    }

    override func tearDown() {}
}
