//
//  ImpressionHasherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 16/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionHasherTest: XCTestCase {
    var testImpression: Impression!
    var testHash: UInt32!

    override func setUp() {}

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
        var impression = baseImpression()
        impression.featureName = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func noCrashWhenKeySplitChangeNumberNull() {
        var impression = baseImpression()
        impression.changeNumber = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func noCrashWhenAppliedRuleNull() {
        var impression = baseImpression()
        impression.label = nil

        let _ = ImpressionHasher.process(impression: impression)

        XCTAssertNotNil(impression)
    }

    func baseImpression() -> KeyImpression {
        return createImpression()
    }

    func createImpression(
        key: String = "someKey",
        feature: String = "someFeature",
        treatment: String = "someTreatment",
        label: String = "someLabel",
        changeNumber: Int64 = 123) -> KeyImpression {
        return KeyImpression(
            featureName: feature,
            keyName: key,
            bucketingKey: nil,
            treatment: treatment,
            label: label,
            time: Date().unixTimestamp(),
            changeNumber: changeNumber,
            previousTime: nil,
            storageId: nil)
    }
}
