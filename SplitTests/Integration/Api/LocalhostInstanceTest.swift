//
//  LocalhostInstanceTest.swift
//  SplitSdkTimeoutTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class LocalhostInstanceTest: XCTestCase {
    let kNeverRefreshRate = 9999999

    func testSdkTimeout() throws {
        let apiKey = "localhost"
        let matchingKey = "CUSTOMER_ID"

        let splitConfig = SplitClientConfig()
        splitConfig.splitFile = "localhost_pepe.yaml"

        let key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
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

        let treatment = client?.getTreatment("split_0")
        wait(for: [sdkReadyExpectation], timeout: 5)

        XCTAssertEqual("off", treatment)

        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }
}
