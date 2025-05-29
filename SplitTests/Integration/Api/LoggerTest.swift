//
//  LoggerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 08-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

@testable import Split
import XCTest

class LoggerTest: XCTestCase {
    let printer = LogPrinterStub()

    override func setUp() {
        printer.clear()
        Logger.shared.printer = printer
    }

    func testNone() {
        Logger.shared.level = .none

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertFalse(isLogged(level: .warning))
        XCTAssertFalse(isLogged(level: .error))
    }

    func testVerbose() {
        Logger.shared.level = .verbose

        logAll()

        XCTAssertTrue(isLogged(level: .verbose))
        XCTAssertTrue(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testDebug() {
        Logger.shared.level = .debug

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertTrue(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testInfo() {
        Logger.shared.level = .info

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertTrue(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testWarning() {
        Logger.shared.level = .warning

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertTrue(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    func testError() {
        Logger.shared.level = .error

        logAll()

        XCTAssertFalse(isLogged(level: .verbose))
        XCTAssertFalse(isLogged(level: .debug))
        XCTAssertFalse(isLogged(level: .info))
        XCTAssertFalse(isLogged(level: .warning))
        XCTAssertTrue(isLogged(level: .error))
    }

    private func isLogged(level: SplitLogLevel) -> Bool {
        return !printer.logs.filter { $0.contains("\(level.rawValue)") }.isEmpty
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
        printer.clear()
    }
}
