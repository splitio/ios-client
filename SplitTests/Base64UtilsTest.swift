//
//  Base64UtilsTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class Base64UtilsTest: XCTestCase {
    override func setUp() {}

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

    func testRealToken() {
        let token =
            "eyJ4LWFibHktY2FwYWJpbGl0eSI6IntcIk1qRXlNekE1TURZeE1nPT1fTWpVNE5qYzJOekk0TUE9PV9NVGs1TlRnM09UTTFfbXlTZWdtZW50c1wiOltcInN1YnNjcmliZVwiXSxcIk1qRXlNekE1TURZeE1nPT1fTWpVNE5qYzJOekk0TUE9PV9zcGxpdHNcIjpbXCJzdWJzY3JpYmVcIl0sXCJjb250cm9sX3ByaVwiOltcInN1YnNjcmliZVwiLFwiY2hhbm5lbC1tZXRhZGF0YTpwdWJsaXNoZXJzXCJdLFwiY29udHJvbF9zZWNcIjpbXCJzdWJzY3JpYmVcIixcImNoYW5uZWwtbWV0YWRhdGE6cHVibGlzaGVyc1wiXX0iLCJ4LWFibHktY2xpZW50SWQiOiJjbGllbnRJZCIsImV4cCI6MTYwMzQwODUwNywiaWF0IjoxNjAzNDA0OTA3fQ=="

        let dec = Data(base64Encoded: token, options: Data.Base64DecodingOptions(rawValue: 0))

        XCTAssertNotNil(dec)
    }

    override func tearDown() {}
}
