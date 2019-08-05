//
//  SplitIntegrationTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitIntegrationTests: XCTestCase {
    
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
        webServer.routeGet(path: "/mySegments/:user_id", data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, { \"id\":\"id1\", \"name\":\"segment2\"}]}")
        webServer.routeGet(path: "/splitChanges?since=:param", data: try? Json.encodeToJson(splitChange))
        webServer.routePost(path: "/events/bulk", data: nil)
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
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.targetSdkEndPoint = "http://localhost:8080"
        splitConfig.targetEventsEndPoint = "http://localhost:8080"
        splitConfig.impressionListener = { impression in
            impressions[self.buildImpressionKey(impression: impression)] = impression
        }
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory?.client
        let manager = factory?.manager
        
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
        
        let t1 = client?.getTreatment("FACUNDO_TEST")
        let t2 = client?.getTreatment("NO_EXISTING_FEATURE")
        let treatmentConfigEmojis = client?.getTreatmentWithConfig("Welcome_Page_UI")
        
        let ts1 = client?.getTreatments(splits: ["testing222", "NO_EXISTING_FEATURE1", "NO_EXISTING_FEATURE2"], attributes: nil)
        let s1 = manager?.split(featureName: "FACUNDO_TEST")
        let s2 = manager?.split(featureName: "NO_EXISTING_FEATURE")
        let splits = manager?.splits
        
        let i1 = impressions[buildImpressionKey(key: "CUSTOMER_ID", splitName: "FACUNDO_TEST", treatment: "off")]
        let i2 = impressions[buildImpressionKey(key: "CUSTOMER_ID", splitName: "NO_EXISTING_FEATURE", treatment: SplitConstants.CONTROL)]
        
        for i in 0..<101 {
            _ = client?.track(eventType: "account", value: Double(i))
        }
        
        sleep(3)
        
        let event99 = getTrackEventBy(value: 99.0)
        let event100 = getTrackEventBy(value: 100.0)
        
        XCTAssertTrue(existsFolder(name: dataFolderName))
        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual("off", t1)
        XCTAssertEqual(SplitConstants.CONTROL, t2)
        XCTAssertEqual("{\"the_emojis\":\"\\uD83D\\uDE01 -- áéíóúöÖüÜÏëç\"}", treatmentConfigEmojis?.config)
        XCTAssertEqual(SplitConstants.CONTROL, ts1?["NO_EXISTING_FEATURE1"])
        XCTAssertEqual(SplitConstants.CONTROL, ts1?["NO_EXISTING_FEATURE2"])
        
        XCTAssertEqual(30, splits?.count)
        XCTAssertNotNil(s1)
        XCTAssertNil(s2)
        XCTAssertNotNil(i1)
        XCTAssertNil(i2)
        XCTAssertEqual("not in split", i1?.label) // TODO: Uncomment when impressions split name is added to impression listener
        XCTAssertEqual(10, tracksHits().count)
        XCTAssertNotNil(event99)
        XCTAssertNil(event100)
    }
    
    
    func testSdkTimeout() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
        let dataFolderName = "2a1099049fd8653247c5ea42bOIajMRhH0R0FcBwJZM4ca7zj6HAq1ZDS"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        var impressions = [String:Impression]()
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 99999
        splitConfig.segmentsRefreshRate = 99999
        splitConfig.impressionRefreshRate = 99999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.impressionListener = { impression in
            impressions[self.buildImpressionKey(impression: impression)] = impression
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
        
        XCTAssertTrue(existsFolder(name: dataFolderName))
        XCTAssertFalse(sdkReadyFired)
        XCTAssertTrue(timeOutFired)
        
    }
    
    private func loadSplitsChangeFile() -> SplitChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }
    
    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self) {
            return change
        }
        return nil
    }
    
    private func existsFolder(name: String) -> Bool {
        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let folder = cachesDirectory.appendingPathComponent(name)
            return fileManager.fileExists(atPath: folder.path)
        } catch {
        }
        return false
    }
    private func buildImpressionKey(impression: Impression) -> String {
        return buildImpressionKey(key: impression.keyName!, splitName: impression.feature!, treatment: impression.treatment!)
    }
    
    private func buildImpressionKey(key: String, splitName: String, treatment: String) -> String {
        return "(\(key)_\(splitName)_\(treatment)"
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

