//
//  ConfigTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ConfigTest: XCTestCase {
    var config = SplitClientConfig()

    // MARK: ImpressionsMode

    func testImpressionsModeEmpty() {
        config.impressionsMode = ""

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, config.impressionsMode)
        XCTAssertEqual(ImpressionsMode.optimized, config.$impressionsMode)
    }

    func testImpressionsModeInvalid() {
        config.impressionsMode = "invalid"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, config.impressionsMode)
        XCTAssertEqual(ImpressionsMode.optimized, config.$impressionsMode)
    }

    func testImpressionsModeoptimized() {
        config.impressionsMode = "optimized"

        XCTAssertEqual(ImpressionsMode.optimized.rawValue, config.impressionsMode)
        XCTAssertEqual(ImpressionsMode.optimized, config.$impressionsMode)
    }

    func testImpressionsModedebug() {
        config.impressionsMode = "debug"

        XCTAssertEqual(ImpressionsMode.debug.rawValue, config.impressionsMode)
        XCTAssertEqual(ImpressionsMode.debug, config.$impressionsMode)
    }

    func testImpressionsModenone() {
        config.impressionsMode = "none"

        XCTAssertEqual(ImpressionsMode.none.rawValue, config.impressionsMode)
        XCTAssertEqual(ImpressionsMode.none, config.$impressionsMode)
    }
}
