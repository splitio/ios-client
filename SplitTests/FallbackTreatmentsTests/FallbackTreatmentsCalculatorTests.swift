//  Copyright © 2025 Split. All rights reserved.

import XCTest
@testable import Split

final class DefaultFallbackTreatmentsCalculatorTests: XCTestCase {

    func testResolveReturnsByFlagFallback() {
        let config = FallbackTreatmentsConfig.Builder()
            .global(FallbackTreatment(treatment: "global"))
            .byFlag(["flag1": FallbackTreatment(treatment: "t1")])
            .build()
        let calculator = DefaultFallbackTreatmentsCalculator(fallbacksConfig: config)

        let result = calculator.resolve(flagName: "flag1", label: "testLabel")
        XCTAssertEqual(result.treatment, "t1")
        XCTAssertEqual(result.label, "fallback - testLabel")
    }

    func testResolveReturnsGlobalFallbackIfFlagMissing() {
        let config = FallbackTreatmentsConfig.Builder()
            .global(FallbackTreatment(treatment: "global"))
            .build()
        let calculator = DefaultFallbackTreatmentsCalculator(fallbacksConfig: config)

        let result = calculator.resolve(flagName: "unknownFlag", label: "testLabel")
        XCTAssertEqual(result.treatment, "global")
        XCTAssertEqual(result.label, "fallback - testLabel")
    }

    func testResolveReturnsControlIfNoFallbacks() {
        let config = FallbackTreatmentsConfig.Builder()
            .build()
        let calculator = DefaultFallbackTreatmentsCalculator(fallbacksConfig: config)

        let result = calculator.resolve(flagName: "anyFlag", label: "testLabel")
        XCTAssertEqual(result.treatment, SplitConstants.control)
        XCTAssertEqual(result.label, "testLabel")
    }

    func testResolveWithNilLabel() {
        let config = FallbackTreatmentsConfig.Builder()
            .byFlag(["flag1":FallbackTreatment(treatment: "t1")])
            .build()
        let calculator = DefaultFallbackTreatmentsCalculator(fallbacksConfig: config)

        let result = calculator.resolve(flagName: "flag1", label: nil)
        XCTAssertEqual(result.treatment, "t1")
        XCTAssertNil(result.label)
    }
}
