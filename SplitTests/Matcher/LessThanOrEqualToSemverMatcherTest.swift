//
//  LessThanOrEqualToSemverMatcherTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class LessThanOrEqualToSemverMatcherTest: XCTestCase {
    func testMatchShouldReturnFalseWhenGreater() {
        XCTAssertFalse(match(this: "1.2.3", to: "1.2.4"))
    }

    func testMatchShouldReturnTrueWhenEqual() {
        XCTAssertTrue(match(this: "1.2.3", to: "1.2.3"))
    }

    func testMatchShouldReturnTrueWhenLess() {
        XCTAssertTrue(match(this: "1.2.3", to: "1.2.2"))
    }

    func testMatchWithPreReleaseShouldReturnTrue() {
        XCTAssertTrue(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.89", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88"))
    }

    func testMatchWithMetadataShouldReturnTrue() {
        XCTAssertTrue(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.2+metadata"))
    }

    func testMatchWithMetadataShouldReturnFalse() {
        XCTAssertFalse(match(this: "2.2.2-rc.2+metadata-lalal", to: "2.2.2-rc.3+metadata"))
    }

    func testMatchWithNullTargetShouldReturnFalse() {
        XCTAssertFalse(match(this: nil, to: "1.2.3"))
    }

    func testMatchWithNullKeyShouldReturnNull() {
        XCTAssertFalse(match(this: "1.2.3", to: nil))
    }

    func testGeneralMatches() {
        let matcher = LessThanOrEqualToSemverMatcher(data: "1.2.3")
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: "2.2.3", matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: 10, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: ["value"], matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: DateTime(), matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: true, matchingKey: "test"), context: nil))
        XCTAssertTrue(matcher.evaluate(values: EvalValues(matchValue: "1.2.3-rc1", matchingKey: "test"), context: nil))
    }

    private func match(this: String?, to: String?) -> Bool {
        return LessThanOrEqualToSemverMatcher(data: this).evaluate(
            values: EvalValues(matchValue: to, matchingKey: "test"),
            context: nil)
    }
}
