//
//  FlushTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class FlushTests: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    var splitChange: SplitChange?
    
    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {
        webServer = MockWebServer()
        webServer.routePost(path: "/events/bulk", data: nil)
        webServer.routePost(path: "/testImpressions/bulk", data: nil)
        webServer.start()
    }
    
    private func stopServer() {
        webServer.stop()
    }
    
    func testControlTreatment() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
        let dataFolderName = "2a1099049fd8653247c5ea42bOIajMRhH0R0FcBwJZM4ca7zj6HAq1ZDS"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        var impressions = [String:Impression]()
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 999999
        splitConfig.segmentsRefreshRate = 999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.eventsPushRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.targetSdkEndPoint = "http://localhost:8080"
        splitConfig.targetEventsEndPoint = "http://localhost:8080"
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory?.client
        
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")
        let serverExpectation = XCTestExpectation(description: "Server Expectation")

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

        for i in 0..<10 {
            sleep(1)
            _ = client?.getTreatment("FACUNDO_TEST")
            _ = client?.getTreatment("Test_Save_1")
            _ = client?.getTreatment("NO_EXISTING_FEATURE_\(i)")
        }

        for i in 0..<101 {
            _ = client?.track(eventType: "account", value: Double(i))
        }
        
        wait(for: [serverExpectation], timeout: 4000.0)
        
        let event99 = getTrackEventBy(value: 99.0)
        let event100 = getTrackEventBy(value: 100.0)
        
        XCTAssertTrue(existsFolder(name: dataFolderName))
        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual(10, tracksHits().count)
        XCTAssertNotNil(event99)
        XCTAssertNil(event100)
    }
    
    private func buildEventsFromJson(content: String) throws -> [EventDTO] {
        return try Json.dynamicEncodeFrom(json: content, to: [EventDTO].self)
    }
    
        private func tracksHits() -> [ReceivedRequest] {
            return webServer.receivedRequests.filter { $0.path == "/events/bulk"}
        }
        
    private func getLastTrackEventJsonHit() -> String {
        let trackRecs = tracksHits()
        return trackRecs[trackRecs.count  - 1].data!
    }
    
    private func getTrackEventBy(value: Double) -> EventDTO? {
        let hits = tracksHits()
        for req in hits {
            var lastEventHitEvents: [EventDTO] = []
            do {
                lastEventHitEvents = try buildEventsFromJson(content: req.data!)
            } catch {
                print("error: \(error)")
            }
            let events = lastEventHitEvents.filter { $0.value == value }
            if events.count > 0 {
                return events[0]
            }
        }
        return nil
    }
}

