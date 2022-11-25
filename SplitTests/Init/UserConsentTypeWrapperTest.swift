//
//  UserConsentTypeTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class UserConsentTypeWrapperTest: XCTestCase {

    func testEmptyInvalidValue() {
        @UserConsentProperty var value: String = ""
        // Initial value is "", should be mapped as "GRANTED"
        XCTAssertEqual(UserConsent.granted.rawValue, value)
        XCTAssertEqual(UserConsent.granted, $value) // Projected value
    }

    func testInvalidValue() {
        @UserConsentProperty var value: String = "invalid"

        XCTAssertEqual(UserConsent.granted.rawValue, value)
        XCTAssertEqual(UserConsent.granted, $value) // Projected value
    }

    func testInitGrantedValue() {
        @UserConsentProperty var value: String = "granted"

        XCTAssertEqual(UserConsent.granted.rawValue, value)
        XCTAssertEqual(UserConsent.granted, $value) // Projected value
    }

    func testInitDeclinedValue() {
        @UserConsentProperty var value: String = "declined"

        XCTAssertEqual(UserConsent.declined.rawValue, value)
        XCTAssertEqual(UserConsent.declined, $value) // Projected value
    }

    func testInitUnknownValue() {
        @UserConsentProperty var value: String = "unknown"

        XCTAssertEqual(UserConsent.unknown.rawValue, value)
        XCTAssertEqual(UserConsent.unknown, $value) // Projected value
    }

    func testGrantedValue() {
        @UserConsentProperty var value: String = ""
        value = "granted"

        XCTAssertEqual(UserConsent.granted.rawValue, value)
        XCTAssertEqual(UserConsent.granted, $value) // Projected value
    }

    func testDeclinedValue() {
        @UserConsentProperty var value: String = ""
        value = "declined"

        XCTAssertEqual(UserConsent.declined.rawValue, value)
        XCTAssertEqual(UserConsent.declined, $value) // Projected value
    }

    func testUnknownValue() {
        @UserConsentProperty var value: String = ""
        value = "unknown"

        XCTAssertEqual(UserConsent.unknown.rawValue, value)
        XCTAssertEqual(UserConsent.unknown, $value) // Projected value
    }

    override func tearDown() {
    }
}

