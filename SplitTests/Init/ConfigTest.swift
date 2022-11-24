//
//  ConfigTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ConfigTest: XCTestCase {
    var config = SplitClientConfig()

    func testUserConsentEmpty() {
        config.userConsent = ""

        XCTAssertEqual(UserConsent.granted.rawValue, config.userConsent)
        XCTAssertEqual(UserConsent.granted, config.$userConsent)
    }

    func testUserConsentInvalid() {
        config.userConsent = "invalid"

        XCTAssertEqual(UserConsent.granted.rawValue, config.userConsent)
        XCTAssertEqual(UserConsent.granted, config.$userConsent)
    }

    func testUserConsentGranted() {
        config.userConsent = "GraNTed"

        XCTAssertEqual(UserConsent.granted.rawValue, config.userConsent)
        XCTAssertEqual(UserConsent.granted, config.$userConsent)
    }

    func testUserConsentDeclined() {
        config.userConsent = "declined"

        XCTAssertEqual(UserConsent.declined.rawValue, config.userConsent)
        XCTAssertEqual(UserConsent.declined, config.$userConsent)
    }

    func testUserConsentUnknown() {
        config.userConsent = "unknowN"

        XCTAssertEqual(UserConsent.unknown.rawValue, config.userConsent)
        XCTAssertEqual(UserConsent.unknown, config.$userConsent)
    }
}

