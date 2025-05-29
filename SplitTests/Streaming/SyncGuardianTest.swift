//
//  SyncGuardianTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SyncGuardianTest: XCTestCase {
    var splitConfig: SplitClientConfig!

    override func setUp() {
        splitConfig = SplitClientConfig()
        splitConfig.syncEnabled = true
        splitConfig.streamingEnabled = true
    }

    func testFirstUpdate() {
        let now = Date()
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 100,
            splitConfig: splitConfig,
            timestampProvider: { now.unixTimestampInMiliseconds() })

        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(guardian.mustSync())
    }

    func testMustSyncWhenTimeExceeds() {
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 100,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(guardian.mustSync())
    }

    func testMustNotSyncWhenTimeDoesNotExceed() {
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 1000,
            splitConfig: splitConfig,
            timestampProvider: {
                Date(timeIntervalSince1970: 200).unixTimestampInMiliseconds()
            })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(guardian.mustSync())
    }

    func testMustNoSyncStreamingDisabled() {
        splitConfig.streamingEnabled = false
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 20,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(guardian.mustSync())
    }

    func testMustNoSyncDisabled() {
        splitConfig.syncEnabled = false
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 20,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(guardian.mustSync())
    }

    func testMinPeriodValidation() {
        // Sync period is based on streaming delay
        // but it can be increased only
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 2000,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.updateLastSyncTimestamp()
        guardian.setMaxSyncPeriod(1)
        Thread.sleep(forTimeInterval: 0.2)
        guardian.updateLastSyncTimestamp()
        XCTAssertFalse(guardian.mustSync())
    }

    func testUpdatePeriodValidation() {
        // Sync period is based on streaming delay
        // but it can be increased only
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 1,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.setMaxSyncPeriod(2000)
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.3)
        guardian.updateLastSyncTimestamp()
        XCTAssertFalse(guardian.mustSync())
    }

    func testIncreaseAndDecreasePeriodValidation() {
        // Sync period is based on streaming delay
        // but it can be increased only
        let guardian = DefaultSyncGuardian(
            maxSyncPeriod: 1,
            splitConfig: splitConfig,
            timestampProvider: { Date().unixTimestampInMicroseconds() })

        // Checking that validation in agains default value
        guardian.setMaxSyncPeriod(2000)
        guardian.setMaxSyncPeriod(1)
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        guardian.updateLastSyncTimestamp()
        XCTAssertTrue(guardian.mustSync())
    }
}
