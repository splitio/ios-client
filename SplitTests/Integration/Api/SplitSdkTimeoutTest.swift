//
//  SplitSdkTimeoutTests.swift
//  SplitSdkTimeoutTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SplitSdkTimeoutTests: XCTestCase {
    let kNeverRefreshRate = 9999999

    func testSdkTimeout() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_a"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        var impressions = [String: Impression]()

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 99999
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 20000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.impressionListener = { impression in
            impressions[IntegrationHelper.buildImpressionKey(impression: impression)] = impression
        }

        let key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory?.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        var timeOutFired = false
        var sdkReadyFired = false

        client?.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReadyExpectation.fulfill()
        }

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation], timeout: 400000.0)

        XCTAssertFalse(sdkReadyFired)
        XCTAssertTrue(timeOutFired)

        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }
}
