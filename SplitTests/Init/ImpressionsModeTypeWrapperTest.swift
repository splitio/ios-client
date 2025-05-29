//
//  ImpressionsModeTypeTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsModeTypeWrapperTest: XCTestCase {
    func testEmptyInvalidValue() {
        @ImpressionsModeProperty var value = ""
        // Initial value is "", should be mapped as "optimized"
        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInvalidValue() {
        @ImpressionsModeProperty var value = "invalid"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInitoptimizedValue() {
        @ImpressionsModeProperty var value = "optimized"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testInitdebugValue() {
        @ImpressionsModeProperty var value = "debug"

        XCTAssertEqual(ImpressionsMode.debug.rawValue, value)
        XCTAssertEqual(ImpressionsMode.debug, $value) // Projected value
    }

    func testInitnoneValue() {
        @ImpressionsModeProperty var value = "none"

        XCTAssertEqual(ImpressionsMode.none.rawValue, value)
        XCTAssertEqual(ImpressionsMode.none, $value) // Projected value
    }

    func testoptimizedValue() {
        @ImpressionsModeProperty var value = ""
        value = "optimized"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, value)
        XCTAssertEqual(ImpressionsMode.optimized, $value) // Projected value
    }

    func testdebugValue() {
        @ImpressionsModeProperty var value = ""
        value = "debug"

        XCTAssertEqual(ImpressionsMode.debug.rawValue, value)
        XCTAssertEqual(ImpressionsMode.debug, $value) // Projected value
    }

    func testnoneValue() {
        @ImpressionsModeProperty var value = ""
        value = "none"

        XCTAssertEqual(ImpressionsMode.none.rawValue, value)
        XCTAssertEqual(ImpressionsMode.none, $value) // Projected value
    }

    override func tearDown() {}
}
