//
//  FetcherThrottleTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11/09/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class FetcherThrottleTests: XCTestCase {
    override func setUp() {}

    func testDelayValues() {
        let v1 = FetcherThrottle.computeDelay(algo: .murmur332, userKey: "nicolas@split.io", seed: 0, timeMillis: 300)
        let v2 = FetcherThrottle.computeDelay(algo: .murmur332, userKey: "emi@split.io", seed: 1, timeMillis: 60000)
        let v3 = FetcherThrottle.computeDelay(algo: .murmur332, userKey: "emi@split.io", seed: 0, timeMillis: 60000)
        let v4 = FetcherThrottle.computeDelay(
            algo: .murmur332,
            userKey: IntegrationHelper.dummyUserKey,
            seed: 1,
            timeMillis: 2900)
        let v5 = FetcherThrottle.computeDelay(
            algo: .murmur332,
            userKey: IntegrationHelper.dummyUserKey,
            seed: 0,
            timeMillis: 0)
        let v6 = FetcherThrottle.computeDelay(
            algo: .murmur364,
            userKey: IntegrationHelper.dummyUserKey,
            seed: 0,
            timeMillis: 0)

        XCTAssertEqual(241, v1)
        XCTAssertEqual(14389, v2)
        XCTAssertEqual(24593, v3)
        XCTAssertEqual(1029, v4)
        XCTAssertEqual(0, v5)
        XCTAssertEqual(0, v6)
    }
}
