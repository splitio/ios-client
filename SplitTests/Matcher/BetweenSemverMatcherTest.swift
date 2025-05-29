//
//  BetweenSemverMatcherTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

final class BetweenSemverMatcherTest: XCTestCase {
    func testMatchShouldReturnTrueWhenBetween() {
        let matcher = buildMatcher("1.2.3", "1.2.5")

        let result = matcher.evaluate(values: buildValues("1.2.4"), context: nil)

        XCTAssertTrue(result)
    }

    func testMatchShouldReturnFalseWhenLess() {
        let matcher = buildMatcher("1.2.3", "1.2.5")

        let result = matcher.evaluate(values: buildValues("1.2.2"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchShouldReturnFalseWhenGreater() {
        let matcher = buildMatcher("1.2.3", "1.2.5")

        let result = matcher.evaluate(values: buildValues("1.2.6"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithPreReleaseShouldReturnTrueWhenBetween() {
        let matcher = buildMatcher("1.1.1-rc.1.1.1", "1.1.1-rc.1.1.3")

        let result = matcher.evaluate(values: buildValues("1.1.1-rc.1.1.2"), context: nil)

        XCTAssertTrue(result)
    }

    func testMatchWithPreReleaseShouldReturnFalseWhenLess() {
        let matcher = buildMatcher("1.1.1-rc.1.1.1", "1.1.1-rc.1.1.3")

        let result = matcher.evaluate(values: buildValues("1.1.1-rc.1.1.0"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithPreReleaseShouldReturnFalseWhenGreater() {
        let matcher = buildMatcher("1.1.1-rc.1.1.1", "1.1.1-rc.1.1.3")

        let result = matcher.evaluate(values: buildValues("1.1.1-rc.1.1.4"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithMetadataShouldReturnFalseWhenLess() {
        let matcher = buildMatcher("2.2.2-rc.3+metadata-lalala", "2.2.2-rc.4+metadata-lalala")

        let result = matcher.evaluate(values: buildValues("2.2.2-rc.2+metadata-lalala"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithMetadataShouldReturnFalseWhenGreater() {
        let matcher = buildMatcher("2.2.2-rc.3+metadata-lalala", "2.2.2-rc.4+metadata-lalala")

        let result = matcher.evaluate(values: buildValues("2.2.2-rc.5+metadata-lalala"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithMetadataShouldReturnTrueWhenBetween() {
        let matcher = buildMatcher("2.2.2-rc.2+metadata-lalala", "2.2.2-rc.4+metadata-lalala")

        let result = matcher.evaluate(values: buildValues("2.2.2-rc.3+metadata-lalala"), context: nil)

        XCTAssertTrue(result)
    }

    func testMatchWithNullStartTargetShouldReturnFalse() {
        let matcher = buildMatcher(nil, "1.2.5")

        let result = matcher.evaluate(values: buildValues("1.2.4"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithNullEndTargetShouldReturnFalse() {
        let matcher = buildMatcher("1.2.3", nil)

        let result = matcher.evaluate(values: buildValues("1.2.4"), context: nil)

        XCTAssertFalse(result)
    }

    func testMatchWithNullKeyShouldReturnFalse() {
        let matcher = buildMatcher("1.2.3", "1.2.5")

        let result = matcher.evaluate(values: buildValues(nil), context: nil)

        XCTAssertFalse(result)
    }

    func testGeneralMatches() {
        let matcher = buildMatcher("2.2.2+metadata-lalala", "3.4.5+metadata-lalala")

        XCTAssertTrue(matcher.evaluate(values: buildValues("2.2.3"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: buildValues(10), context: nil))
        XCTAssertFalse(matcher.evaluate(values: buildValues(["value"]), context: nil))
        XCTAssertFalse(matcher.evaluate(values: buildValues(DateTime()), context: nil))
        XCTAssertFalse(matcher.evaluate(values: buildValues(false), context: nil))
        XCTAssertFalse(matcher.evaluate(values: buildValues("5.2.2-rc.1"), context: nil))
    }

    private func buildMatcher(_ from: String?, _ to: String?) -> BetweenSemverMatcher {
        let data = BetweenStringMatcherData()
        data.start = from
        data.end = to
        return BetweenSemverMatcher(data: data)
    }

    private func buildValues(_ version: Any?) -> EvalValues {
        return EvalValues(matchValue: version, matchingKey: "test")
    }
}
