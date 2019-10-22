//
//  SplitIntegrationTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitSdkTiemoutTests: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    
    override func setUp() {
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {
        webServer = MockWebServer()
        webServer.routeGet(path: "/mySegments/:user_id", data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}")
        webServer.start()
    }
    
    private func stopServer() {
        webServer.stop()
    }
    
    func testSdkTimeout() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_a"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        var impressions = [String:Impression]()
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
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
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
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
        
        wait(for: [sdkReadyExpectation], timeout: 400000.0)

        XCTAssertFalse(sdkReadyFired)
        XCTAssertTrue(timeOutFired)
        
    }
}

