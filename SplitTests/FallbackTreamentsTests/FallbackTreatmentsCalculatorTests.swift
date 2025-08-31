//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

final class DefaultFallbackTreatmentsCalculatorTests: XCTestCase {

    func testResolveReturnsByFlagFallback() {
        let treatment = FallbackTreatment(treatment: "t1")
        let config = FallbackConfig(
            global: FallbackTreatment(treatment: "global"),
            byFlag: ["flag1": treatment]
        )
        let calculator = DefaultFallbackTreatmentsCalculator(factory: config)

        let result = calculator.resolve(flagName: "flag1", label: "testLabel")
        XCTAssertEqual(result.treatment, "t1")
        XCTAssertEqual(result.label, "fallback - testLabel")
    }

    func testResolveReturnsGlobalFallbackIfFlagMissing() {
        let global = FallbackTreatment(treatment: "global")
        let config = FallbackConfig(
            global: global,
            byFlag: [:]
        )
        let calculator = DefaultFallbackTreatmentsCalculator(factory: config)

        let result = calculator.resolve(flagName: "unknownFlag", label: "label")
        XCTAssertEqual(result.treatment, "global")
        XCTAssertEqual(result.label, "fallback - label")
    }

    func testResolveReturnsControlIfNoFallbacks() {
        let config = FallbackConfig(
            global: nil,
            byFlag: [:]
        )
        let calculator = DefaultFallbackTreatmentsCalculator(factory: config)

        let result = calculator.resolve(flagName: "anyFlag", label: "label")
        XCTAssertEqual(result.treatment, SplitConstants.control)
        XCTAssertEqual(result.label, "fallback - label")
    }

    func testResolveWithNilLabel() {
        let treatment = FallbackTreatment(treatment: "t1")
        let config = FallbackConfig(
            global: nil,
            byFlag: ["flag1": treatment]
        )
        let calculator = DefaultFallbackTreatmentsCalculator(factory: config)

        let result = calculator.resolve(flagName: "flag1", label: nil)
        XCTAssertEqual(result.treatment, "t1")
        XCTAssertNil(result.label)
    }
}
