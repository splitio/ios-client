//
//  OutdatedSplitProxyHandlerTests.swift
//  SplitTests
//
//  Created on 13/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

@testable import Split
import XCTest

class OutdatedSplitProxyHandlerTests: XCTestCase {
    private var mockStorage: GeneralInfoStorageMock!
    private var handler: OutdatedSplitProxyHandler!

    private let latestSpec = "1.3"
    private let previousSpec = "1.2"
    private let proxyCheckInterval: Int64 = 3600000 // 1 hour in milliseconds

    override func setUp() {
        super.setUp()
        mockStorage = GeneralInfoStorageMock()
        handler = OutdatedSplitProxyHandler(
            flagSpec: latestSpec,
            previousSpec: previousSpec,
            generalInfoStorage: mockStorage,
            proxyCheckIntervalMillis: proxyCheckInterval)
    }

    override func tearDown() {
        mockStorage = nil
        handler = nil
        super.tearDown()
    }

    func testInitialStateIsNoneAndUsesLatestSpec() {
        XCTAssertEqual(handler.getCurrentSpec(), latestSpec)
        XCTAssertFalse(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())
    }

    func testProxyErrorTriggersFallbackModeAndUsesPreviousSpec() {
        handler.trackProxyError()

        XCTAssertEqual(handler.getCurrentSpec(), previousSpec)
        XCTAssertTrue(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())

        XCTAssertNotEqual(mockStorage.lastProxyUpdateTimestamp, 0)
    }

    func testPerformProxyCheckWithNoError() {
        mockStorage.lastProxyUpdateTimestamp = 0
        handler.performProxyCheck()

        XCTAssertEqual(handler.getCurrentSpec(), latestSpec)
        XCTAssertFalse(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())
    }

    func testFallbackModePersistsUntilIntervalElapses() {
        let currentTime = Date.nowMillis()
        mockStorage.lastProxyUpdateTimestamp = currentTime - 1000 // 1 second ago

        handler.performProxyCheck()

        XCTAssertEqual(handler.getCurrentSpec(), previousSpec)
        XCTAssertTrue(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())
    }

    func testIntervalElapsedEntersRecoveryModeAndUsesLatestSpec() {
        let currentTime = Date.nowMillis()
        mockStorage.lastProxyUpdateTimestamp = currentTime - proxyCheckInterval - 1000

        handler.performProxyCheck()

        XCTAssertEqual(handler.getCurrentSpec(), latestSpec)
        XCTAssertFalse(handler.isFallbackMode())
        XCTAssertTrue(handler.isRecoveryMode())
    }

    func testRecoveryModeResetsToNoneAfterResetProxyCheckTimestamp() {
        handler.trackProxyError()
        XCTAssertTrue(handler.isFallbackMode())

        handler.resetProxyCheckTimestamp()

        handler.performProxyCheck()

        XCTAssertEqual(handler.getCurrentSpec(), latestSpec)
        XCTAssertFalse(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())
    }

    func testRecoveryToFallbackTransition() {
        let currentTime = Date.nowMillis()
        mockStorage.lastProxyUpdateTimestamp = currentTime - proxyCheckInterval - 1000
        handler.performProxyCheck()
        XCTAssertTrue(handler.isRecoveryMode())

        handler.trackProxyError()

        XCTAssertEqual(handler.getCurrentSpec(), previousSpec)
        XCTAssertTrue(handler.isFallbackMode())
        XCTAssertFalse(handler.isRecoveryMode())
    }
}
