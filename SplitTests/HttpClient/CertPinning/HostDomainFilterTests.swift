//
//  CredentialPinParserTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class CredentialPinParserTests: XCTestCase {
    override func setUp() {}

    func testPinsForHost() {
        // [CredentialPin]
        let pins = [
            CredentialPin(host: "*.example.com", hash: Data(), algo: .sha256),
            CredentialPin(host: "**.example.com", hash: Data(), algo: .sha256),
            CredentialPin(host: "www.sub.example.com", hash: Data(), algo: .sha256),
        ]

        // Same as android tests
        let res1 = HostDomainFilter.pinsFor(host: "sub.example.com", pins: pins)
        let res2 = HostDomainFilter.pinsFor(host: "www.sub.example.com", pins: pins)
        let res3 = HostDomainFilter.pinsFor(host: "*.", pins: pins)
        let res4 = HostDomainFilter.pinsFor(host: "**.", pins: pins)

        XCTAssertEqual(2, res1.count)
        XCTAssertEqual(1, res1.filter { $0.host == "*.example.com" }.count)
        XCTAssertEqual(1, res1.filter { $0.host == "**.example.com" }.count)

        XCTAssertEqual(2, res2.count)
        XCTAssertEqual(1, res2.filter { $0.host == "**.example.com" }.count)
        XCTAssertEqual(1, res2.filter { $0.host == "www.sub.example.com" }.count)

        XCTAssertEqual(0, res3.count)
        XCTAssertEqual(0, res4.count)
    }
}
