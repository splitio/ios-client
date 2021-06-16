//
//  ImpressionHasherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 16/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionHasherTest: XCTestCase {

    var testImpression: Impression!
    var testHash: UInt32!

    override func setUp() {

    }

    func testDifferentFeature() {
        let impression = createImpression(feature: "someOtherFeature")

        let hash = ImpressionHasher.process(impression: impression)

        XCTAssertNotEqual(testHash, hash)
    }

    func testDifferentKey() {
        let impression = createImpression(key: "someOtherKey")

        let hash = ImpressionHasher.process(impression: impression)

        XCTAssertNotEqual(testHash, hash)
    }

    func testDifferentChangeNumber() {
        let impression = createImpression(changeNumber: 111)

        let hash = ImpressionHasher.process(impression: impression)

        XCTAssertNotEqual(testHash, hash)
    }

    func testDifferentLabel() {
        let impression = createImpression(label: "someOtherLabel")

        let hash = ImpressionHasher.process(impression: impression)

        XCTAssertNotEqual(testHash, hash)
    }

    func testDifferentTreatment() {
        let impression = createImpression(treatment: "someOtherTreatment")

        let hash = ImpressionHasher.process(impression: impression)

        XCTAssertNotEqual(testHash, hash)
    }

    func testNoCrashWhenSplitNull() {
        let impression = baseImpression()
        impression.feature = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func testNoCrashWhenSplitAndKeyNull() {
        let impression = baseImpression()
        impression.keyName = nil
        impression.feature = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func noCrashWhenKeySplitChangeNumberNull() {
        let impression = baseImpression()
        impression.changeNumber = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func noCrashWhenAppliedRuleNull() {
        let impression = baseImpression()
        impression.label = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func baseImpression() -> Impression {
        return createImpression()
    }

    func createImpression(key: String = "someKey",
                          feature: String = "someFeature",
                          treatment: String = "someTreatment",
                          label: String = "someLabel",
                          changeNumber: Int64 = 123) -> Impression {
        let impression = Impression()
        impression.keyName = key
        impression.feature = feature
        impression.treatment = treatment
        impression.time = Date().unixTimestamp()
        impression.label = label
        impression.changeNumber = changeNumber
        return impression
    }
}

