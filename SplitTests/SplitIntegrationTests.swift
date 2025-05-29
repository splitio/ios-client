//
//  SplitIntegrationTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SplitIntegrationTests: XCTestCase {
    let splitConfig: SplitClientConfig = .init()
    let kNeverRefreshRate = 9999999

    override func setUp() {
        splitConfig.featuresRefreshRate = kNeverRefreshRate
        splitConfig.segmentsRefreshRate = kNeverRefreshRate
        splitConfig.impressionRefreshRate = kNeverRefreshRate
        splitConfig.sdkReadyTimeOut = 1
        splitConfig.targetSdkEndPoint = "localhost"
        splitConfig.targetEventsEndPoint = "localhost"
    }

    override func tearDown() {}

    func testControlTreatment() {
        let kTestApiKey = "TEST_API_KEY"
        let kMatchingKey = "test_key"
        let kFeatureOne = "feature_1"
        let kFeatureTwo = "feature_2"

        let key = Key(matchingKey: kMatchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(kTestApiKey).setKey(key).setConfig(splitConfig).build()
        let client = factory?.client
        let sdkTimeOutExpectation = XCTestExpectation(description: "SDK TimeOut Expectation")
        var timeOutFired = false

        client?.on(event: SplitEvent.sdkReadyTimedOut) {
            timeOutFired = true
            sdkTimeOutExpectation.fulfill()
        }

        wait(for: [sdkTimeOutExpectation], timeout: 10.0)

        let treatment = client?.getTreatment(kFeatureOne)
        let treatments = client?.getTreatments(splits: [kFeatureOne, kFeatureTwo], attributes: nil)
        let splitResult = client?.getTreatmentWithConfig(kFeatureOne)
        let splitResults = client?.getTreatmentsWithConfig(splits: [kFeatureOne, kFeatureTwo], attributes: nil)

        XCTAssertTrue(timeOutFired)
        XCTAssertEqual(SplitConstants.CONTROL, treatment)
        XCTAssertEqual(SplitConstants.CONTROL, treatments?[kFeatureOne])
        XCTAssertEqual(SplitConstants.CONTROL, treatments?[kFeatureTwo])
        XCTAssertEqual(SplitConstants.CONTROL, splitResult?.treatment)
        XCTAssertNil(splitResult?.config)

        XCTAssertEqual(SplitConstants.CONTROL, splitResults?[kFeatureOne]?.treatment)
        XCTAssertNil(splitResults?[kFeatureOne]?.config)

        XCTAssertEqual(SplitConstants.CONTROL, splitResults?[kFeatureTwo]?.treatment)
        XCTAssertNil(splitResults?[kFeatureTwo]?.config)
    }
}
