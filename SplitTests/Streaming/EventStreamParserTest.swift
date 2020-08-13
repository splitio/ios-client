//
//  EventStreamParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class EventStreamParserTest: XCTestCase {

    let parser = EventStreamParser()
    var values: [String: String]!

    override func setUp() {
        values = [String: String]()
    }

    func testParseErrorMessage() {
        let res = parser.parseLineAndAppendValue(streamLine: "id:theid", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(1, values.count);
        XCTAssertEqual(values["id"], "theid");
    }

    func testParseColon() {
        let res = parser.parseLineAndAppendValue(streamLine: ":", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(0, values.count);
    }

    func testParseEmptyLineNoEnd() {
        let res = parser.parseLineAndAppendValue(streamLine: "", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(0, values.count);
    }

    func testParseEnd() {
        let res0 = parser.parseLineAndAppendValue(streamLine: "id:theid", messageValues: &values)
        let res1 = parser.parseLineAndAppendValue(streamLine: "event:message", messageValues: &values)
        let res2 = parser.parseLineAndAppendValue(streamLine: "data:{\"c1\":1}", messageValues: &values)
        let res = parser.parseLineAndAppendValue(streamLine: "", messageValues: &values)

        XCTAssertFalse(res0);
        XCTAssertFalse(res1);
        XCTAssertFalse(res2);
        XCTAssertTrue(res);
        XCTAssertEqual(3, values.count);
        XCTAssertEqual("theid", values["id"])
        XCTAssertEqual("message", values["event"])
        XCTAssertEqual("{\"c1\":1}", values["data"])
    }

    func testParseTwoColon() {
        let res = parser.parseLineAndAppendValue(streamLine: "id:value:value", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(1, values.count);
        XCTAssertEqual("value:value", values["id"])
    }

    func testParseNoColon() {
        let res = parser.parseLineAndAppendValue(streamLine: "fieldName", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(1, values.count);
        XCTAssertEqual("", values["fieldName"])
    }

    func testParseNoFieldName() {
        let res = parser.parseLineAndAppendValue(streamLine: ":fieldName", messageValues: &values)

        XCTAssertFalse(res);
        XCTAssertEqual(0, values.count);
    }

    override func tearDown() {
    }
}
