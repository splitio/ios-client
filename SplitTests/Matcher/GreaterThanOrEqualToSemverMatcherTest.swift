//
//  GreaterThanOrEqualToSemverMatcherTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class GreaterThanOrEqualToSemverMatcherTest: XCTestCase {
    func testMatchShouldReturnTrueWhenKeyIsGreater() {
        XCTAssertTrue(match(this: "1.2.3", to: "1.2.4"))
    }

    func testMatchShouldReturnTrueWhenKeyIsEqual() {
        XCTAssertTrue(match(this: "1.2.3", to: "1.2.3"))
    }

    func testMatchShouldReturnFalseWhenKeyIsLess() {
        XCTAssertFalse(match(this: "1.2.3", to: "1.2.2"))
    }

    func testMatchWithPreReleaseShouldReturnTrueWhenEqual() {
        XCTAssertTrue(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88"))
    }

    func testMatchWithPreReleaseShouldReturnTrueWhenGreater() {
        XCTAssertTrue(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.89"))
    }

    func testMatchWithPreReleaseShouldReturnFalseWhenLess() {
        XCTAssertFalse(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.87"))
    }

    func testMatchWithMetadataShouldReturnTrueWhenEqual() {
        XCTAssertTrue(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.2+metadata-lalala"))
    }

    func testMatchWithMetadataShouldReturnTrueWhenGreater() {
        XCTAssertTrue(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.3+metadata-lalala"))
    }

    func testMatchWithMetadataShouldReturnFalseWhenLess() {
        XCTAssertFalse(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.1+metadata-lalala"))
    }

    func testMatchShouldReturnFalseWhenKeyIsNull() {
        XCTAssertFalse(match(this: "1.2.3", to: nil))
    }

    func testGeneralUnsuccessfulMatches() {
        let matcher = GreaterThanOrEqualToSemverMatcher(data: "2.2.2-rc.2+metadata")

        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: 10, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: true, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: ["value"], matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: DateTime(), matchingKey: "test"), context: nil))
    }

    private func match(this: String?, to: String?) -> Bool {
        return GreaterThanOrEqualToSemverMatcher(data: this).evaluate(
            values: EvalValues(matchValue: to, matchingKey: "test"),
            context: nil)
    }
}
