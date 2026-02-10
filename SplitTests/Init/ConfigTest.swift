//
//  ConfigTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ConfigTest: XCTestCase {
    var config = SplitClientConfig()

    override func setUp() {
        super.setUp()
        config = SplitClientConfig()
        // Reset logger level to default (.none) before each test
        Logger.shared.level = SplitLogLevel.none.toLogLevel()
    }

    func testIsDebugModeEnabledGetterReturnsTrueWhenDebug() {
        Logger.shared.level = SplitLogLevel.debug.toLogLevel()

        XCTAssertTrue(config.isDebugModeEnabled)
    }

    func testIsDebugModeEnabledGetterReturnsFalseWhenNotDebug() {
        Logger.shared.level = SplitLogLevel.verbose.toLogLevel()

        XCTAssertFalse(config.isDebugModeEnabled)
    }

    func testIsDebugModeEnabledGetterReturnsFalseWhenNone() {
        Logger.shared.level = SplitLogLevel.none.toLogLevel()

        XCTAssertFalse(config.isDebugModeEnabled)
    }

    func testIsDebugModeEnabledSetterSetsDebugWhenLevelIsNone() {
        // Level starts at .none
        config.isDebugModeEnabled = true

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .debug)
    }

    func testIsDebugModeEnabledSetterKeepsNoneWhenSetToFalse() {
        config.isDebugModeEnabled = false

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .none)
    }

    func testIsDebugModeEnabledSetterDoesNotChangeWhenLevelIsNotNone() {
        Logger.shared.level = SplitLogLevel.warning.toLogLevel()

        config.isDebugModeEnabled = true

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .warning)
    }

    func testIsVerboseModeEnabledGetterReturnsTrueWhenVerbose() {
        Logger.shared.level = SplitLogLevel.verbose.toLogLevel()

        XCTAssertTrue(config.isVerboseModeEnabled)
    }

    func testIsVerboseModeEnabledGetterReturnsFalseWhenNotVerbose() {
        Logger.shared.level = SplitLogLevel.debug.toLogLevel()

        XCTAssertFalse(config.isVerboseModeEnabled)
    }

    func testIsVerboseModeEnabledGetterReturnsFalseWhenNone() {
        Logger.shared.level = SplitLogLevel.none.toLogLevel()

        XCTAssertFalse(config.isVerboseModeEnabled)
    }

    func testIsVerboseModeEnabledSetterSetsVerboseWhenLevelIsNone() {
        config.isVerboseModeEnabled = true

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .verbose)
    }

    func testIsVerboseModeEnabledSetterKeepsNoneWhenSetToFalse() {
        config.isVerboseModeEnabled = false

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .none)
    }

    func testIsVerboseModeEnabledSetterDoesNotChangeWhenLevelIsNotNone() {
        Logger.shared.level = SplitLogLevel.error.toLogLevel()

        config.isVerboseModeEnabled = true

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .error)
    }

    func testLogLevelGetterReturnsCurrentLevel() {
        let levels: [SplitLogLevel] = [.verbose, .debug, .info, .warning, .error, .none]

        for level in levels {
            Logger.shared.level = level.toLogLevel()

            XCTAssertEqual(config.logLevel, level,
                           "Expected logLevel to return \(level)")
        }
    }

    func testSetLogLevelWithValidString() {
        config.set(logLevel: "VERBOSE")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .verbose)

        config.set(logLevel: "DEBUG")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .debug)

        config.set(logLevel: "INFO")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .info)

        config.set(logLevel: "WARNING")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .warning)

        config.set(logLevel: "ERROR")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .error)

        config.set(logLevel: "NONE")
        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .none)
    }

    func testSetLogLevelWithInvalidStringDefaultsToNone() {
        Logger.shared.level = SplitLogLevel.debug.toLogLevel()

        config.set(logLevel: "INVALID")

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .none)
    }

    func testSetLogLevelWithEmptyStringDefaultsToNone() {
        Logger.shared.level = SplitLogLevel.verbose.toLogLevel()

        config.set(logLevel: "")

        XCTAssertEqual(SplitLogLevel.from(Logger.shared.level), .none)
    }

    // MARK: - ImpressionsMode
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

