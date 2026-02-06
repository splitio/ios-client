//
//  LoggerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 08-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import Logging
@testable import Split

import XCTest

// This test verifies that SplitLogLevel mapping to LogLevel works correctly
class LoggerTest : XCTestCase {

    let printer = LogPrinterStub()

    override func setUp() {
        printer.clear()
        Logger.shared.printer = printer
        Logger.shared.dateProvider = SplitDateProvider()
    }

    func testNone() {
        Logger.shared.level = SplitLogLevel.none.toLogLevel()

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertFalse(isLogged(level: .warning))
        XCTAssertFalse(isLogged(level: .error))
    }

    func testVerbose() {
        Logger.shared.level = SplitLogLevel.verbose.toLogLevel()

        logAll()

        XCTAssertTrue(isLogged(level: .verbose))
        XCTAssertTrue(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testDebug() {
        Logger.shared.level = SplitLogLevel.debug.toLogLevel()

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertTrue(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testInfo() {
        Logger.shared.level = SplitLogLevel.info.toLogLevel()

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testWarning() {
        Logger.shared.level = SplitLogLevel.warning.toLogLevel()

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testError() {
        Logger.shared.level = SplitLogLevel.error.toLogLevel()

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertFalse(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testToLogLevelVerbose() {
        XCTAssertEqual(SplitLogLevel.verbose.toLogLevel(), LogLevel.verbose)
    }

    func testToLogLevelDebug() {
        XCTAssertEqual(SplitLogLevel.debug.toLogLevel(), LogLevel.debug)
    }

    func testToLogLevelInfo() {
        XCTAssertEqual(SplitLogLevel.info.toLogLevel(), LogLevel.info)
    }

    func testToLogLevelWarning() {
        XCTAssertEqual(SplitLogLevel.warning.toLogLevel(), LogLevel.warning)
    }

    func testToLogLevelError() {
        XCTAssertEqual(SplitLogLevel.error.toLogLevel(), LogLevel.error)
    }

    func testToLogLevelNone() {
        XCTAssertEqual(SplitLogLevel.none.toLogLevel(), LogLevel.none)
    }

    private func isLogged(level: LogLevel) -> Bool {
        return printer.logs.filter { $0.contains("\(level.rawValue)") }.count > 0
    }

    private func logAll() {
        Logger.v("log")
        Logger.d("log")
        Logger.i("log")
        Logger.w("log")
        Logger.e("log")
    }

    override func tearDown() {
        Logger.shared.printer = DefaultLogPrinter()
        Logger.shared.dateProvider = SplitDateProvider()
        printer.clear()
    }
}

