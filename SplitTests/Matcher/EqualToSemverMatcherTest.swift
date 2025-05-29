//
//  EqualToSemverMatcherTest.swift
//  SplitTests
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class EqualToSemverMatcherTest: XCTestCase {
    func testMatchShouldReturnFalseWhenPatchDiffers() {
        XCTAssertFalse(match(this: "1.0.0", to: "1.0.1"))
    }

    func testMatchShouldReturnTrueWhenVersionsAreEqual() {
        XCTAssertTrue(match(this: "1.1.2", to: "1.1.2"))
    }

    func testMatchWithPreReleaseShouldReturnTrueWhenVersionsAreEqual() {
        XCTAssertTrue(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88"))
    }

    func testMatchWithPreReleaseShouldReturnFalseWhenVersionsDiffer() {
        XCTAssertFalse(match(this: "1.2.3----RC-SNAPSHOT.12.9.1--.12.88", to: "1.2.3----RC-SNAPSHOT.12.9.1--.12.99"))
    }

    func testMatchWithMetadataShouldReturnTrueWhenVersionsAreEqual() {
        XCTAssertTrue(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.2+metadata-lalala"))
    }

    func testMatchWithMetadataShouldReturnFalseWhenVersionsDiffer() {
        XCTAssertFalse(match(this: "2.2.2-rc.2+metadata-lalala", to: "2.2.2-rc.2+metadata"))
    }

    func testMatchShouldReturnFalseWhenTargetIsNull() {
        XCTAssertFalse(match(this: nil, to: "1.0.0"))
    }

    func testMatchShouldReturnFalseWhenKeyIsNull() {
        XCTAssertFalse(match(this: "1.0.0", to: nil))
    }

    func testGeneralUnsuccessfulMatches() {
        let matcher = EqualToSemverMatcher(data: "2.2.2-rc.2+metadata")

        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: true, matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: ["value"], matchingKey: "test"), context: nil))
        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: DateTime(), matchingKey: "test"), context: nil))
    }

    private func match(this: String?, to: String?) -> Bool {
        return EqualToSemverMatcher(data: this).evaluate(
            values: EvalValues(matchValue: to, matchingKey: "test"),
            context: nil)
    }
}
