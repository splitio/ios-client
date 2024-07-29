//
//  CredentialPinParserTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class CredentialPinParserTests: XCTestCase {

    override func setUp() {
    }

    func testPinsForHost() {

        // [CredentialPin]
        let pins = [ CredentialPin(host: "*.example.com", hash: Data(), algo: .sha256),
                     CredentialPin(host: "**.example.com", hash: Data(), algo: .sha256),
                     CredentialPin(host: "www.sub.example.com", hash: Data(), algo: .sha256)
        ]

        // Same as android tests
        let res1 = PinHostParser.pinsFor(host: "sub.example.com", pins: pins)
        let res2 = PinHostParser.pinsFor(host: "www.sub.example.com", pins: pins)
        let res3 = PinHostParser.pinsFor(host: "*.", pins: pins)
        let res4 = PinHostParser.pinsFor(host: "**.", pins: pins)

        XCTAssertEqual(2, res1.count)
        XCTAssertEqual(1, res1.filter { $0.host == "*.example.com" }.count)
        XCTAssertEqual(1, res1.filter { $0.host == "**.example.com"}.count)

        XCTAssertEqual(2, res2.count)
        XCTAssertEqual(1, res2.filter { $0.host == "**.example.com" }.count)
        XCTAssertEqual(1, res2.filter { $0.host == "www.sub.example.com"}.count)

        XCTAssertEqual(0, res3.count)
        XCTAssertEqual(0, res4.count)
    }

    struct PinHostParser {
        static let endString = "$"
        static let mainRegex = "(?:[a-zA-Z0-9_-]+\\.)"
        static let wCards = [(prefix: "**.", pattern: "\(mainRegex)*"),
                             (prefix: "*.", pattern: "\(mainRegex)?")]

        static func pinsFor(host: String, pins: [CredentialPin]) -> [CredentialPin] {
            var foundPins = [CredentialPin]()
            for pin in pins {
                var hasWildcard = false
                for w in wCards {
                    let count = w.prefix.count
                    if pin.host.starts(with: w.prefix), pin.host.count > count {
                        let pinHost = pin.host
                            .suffix(starting: count)
                            .asString()
                            .replacingOccurrences(of: ".", with: "\\.")
                        let regex = "\(w.pattern)\(pinHost)\(endString)"
                        if host.matchRegex(regex) {
                            foundPins.append(pin)
                        }
                        hasWildcard = true
                        continue
                    }
                }
                if !hasWildcard, pin.host == host {
                    foundPins.append(pin)
                }
            }
            return foundPins
        }
    }
}

