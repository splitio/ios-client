//
//  InListSemverMatcherTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class InListSemverMatcherTest: XCTestCase {
    func testMatchShouldReturnTrueWhenInList() {
        XCTAssertTrue(match(target: "1.2.4", within: ["1.2.3", "1.2.5", "1.2.4"]))
    }

    func testMatchShouldReturnFalseWhenNotInList() {
        XCTAssertFalse(match(target: "1.2.6", within: ["1.2.3", "1.2.5", "1.2.4"]))
    }

    func testMatchWithPreReleaseShouldReturnTrueWhenInList() {
        XCTAssertTrue(match(target: "1.1.1-rc.1.1.2", within: ["1.1.1-rc.1.1.1", "1.1.1-rc.1.1.3", "1.1.1-rc.1.1.2"]))
    }

    func testMatchWithPreReleaseShouldReturnFalseWhenNotInList() {
        XCTAssertFalse(match(target: "1.1.1-rc.1.1.4", within: ["1.1.1-rc.1.1.1", "1.1.1-rc.1.1.3", "1.1.1-rc.1.1.2"]))
    }

    func testMatchWithMetadataShouldReturnTrueWhenInList() {
        XCTAssertTrue(match(target: "1.2.4+meta", within: ["1.2.3+meta", "1.2.5+meta", "1.2.4+meta"]))
    }

    func testMatchWithMetadataShouldReturnFalseWhenNotInList() {
        XCTAssertFalse(match(target: "1.2.6+meta", within: ["1.2.3+meta", "1.2.5+meta", "1.2.4+meta"]))
    }

    func testMatchWithNullTargetShouldReturnFalse() {
        XCTAssertFalse(match(target: "1.2.6+meta", within: nil))
    }

    func testMatchWithEmptyListShouldReturnFalse() {
        XCTAssertFalse(match(target: "1.2.6+meta", within: []))
    }

    func testMatchWithNullKeyShouldReturnFalse() {
        XCTAssertFalse(match(target: nil, within: ["1.2.3+meta", "1.2.5+meta", "1.2.4+meta"]))
    }

    func testGeneralMatches() {
        let matcher = InListSemverMatcher(data: ["1.2.3", "1.2.5", "1.2.4"])

        XCTAssertTrue(matcher.evaluate(values: EvalValues(matchValue: "1.2.4", matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: 10, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: ["value"], matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: DateTime(), matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: false, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: "1.2.6", matchingKey: "test"), context: nil))
    }

    private func match(target: Any?, within: [String]?) -> Bool {
        return InListSemverMatcher(data: within).evaluate(
            values: EvalValues(matchValue: target, matchingKey: "test"),
            context: nil)
    }
}
