//
//  Base64UtilsTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class Base64UtilsTest: XCTestCase {
    override func setUp() {

    }

    func testBasicUrlEncoded() {
        let expDecoded = "{\"fieldString\":\"value\", \"fieldInt\": 1, \"fieldBoolean\":true}"
        let encoded = "eyJmaWVsZFN0cmluZyI6InZhbHVlIiwgImZpZWxkSW50IjogMSwgImZpZWxkQm9vbGVhbiI6dHJ1ZX0"

        let decoded = Base64Utils.decodeBase64URL(base64: encoded)

        XCTAssertEqual(expDecoded, decoded)
    }

    func testEmpty() {
        let expDecoded = ""
        let encoded = ""

        let decoded = Base64Utils.decodeBase64URL(base64: encoded)

        XCTAssertEqual(expDecoded, decoded)
    }

    func testNil() {
        let decoded = Base64Utils.decodeBase64URL(base64: nil)

        XCTAssertNil(decoded)
    }

    override func tearDown() {

    }
}
