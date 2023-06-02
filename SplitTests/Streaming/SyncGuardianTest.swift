//
//  SyncGuardianTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SyncGuardianTest: XCTestCase {


    func testFirstUpdate() {
        let now = Date()
        let guardian = DefaultSyncGuardian(maxSyncPeriod: 100,
                                           timestampProvider: { now.unixTimestampInMiliseconds() })

        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(guardian.mustSync())
    }

    func testMustSyncWhenTimeExceeds() {
        let guardian = DefaultSyncGuardian(maxSyncPeriod: 100,
                                           timestampProvider: { Date().unixTimestampInMicroseconds() })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(guardian.mustSync())
    }

    func testMustNotSyncWhenTimeDoesNotExceed() {
        let guardian = DefaultSyncGuardian(maxSyncPeriod: 1000,
                                           timestampProvider: { Date(timeIntervalSince1970: 200).unixTimestampInMiliseconds() })
        guardian.updateLastSyncTimestamp()
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(guardian.mustSync())
    }
}
