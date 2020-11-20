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
    var serverUrl = ""
    
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
        webServer.routePost(path: "/testImpressions/bulk", data: nil)
        webServer.start()
        serverUrl = webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }
    
    func testControlTreatment() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_g"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 999999
        splitConfig.segmentsRefreshRate = 999999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.eventsPushRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 1000
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
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

        for i in 0..<10 {
            sleep(1)
            _ = client?.getTreatment("FACUNDO_TEST")
            _ = client?.getTreatment("Test_Save_1")
            _ = client?.getTreatment("NO_EXISTING_FEATURE_\(i)")
        }

        for i in 0..<100 {
            _ = client?.track(eventType: "account", value: Double(i))
        }
        client?.flush()
        //wait(for: [serverExpectation], timeout: 4000.0)
        sleep(3)

        let event99 = getTrackEventBy(value: 99.0)
        let event100 = getTrackEventBy(value: 100.0)

        let impression1 = getImpressionBy(testName: "FACUNDO_TEST")
        let impression2 = getImpressionBy(testName: "NO_EXISTING_FEATURE_1")

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual(10, tracksHits().count)
        XCTAssertNotNil(event99)
        XCTAssertNil(event100)
        XCTAssertNotNil(impression1)
        XCTAssertNil(impression2)
        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    // MARK: Tracks Hits
    private func buildEventsFromJson(content: String) throws -> [EventDTO] {
        return try Json.dynamicEncodeFrom(json: content, to: [EventDTO].self)
    }
    
    private func tracksHits() -> [ClientRequest] {
        var req: [ClientRequest]!
        DispatchQueue.global().sync {
            req = webServer.receivedRequests
        }
        return req.filter { $0.path == "/events/bulk"}
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

    // MARK: Impressions Hits
    private func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.encodeFrom(json: content, to: [ImpressionsTest].self)
    }

    private func impressionsHits() -> [ClientRequest] {
        return webServer.receivedRequests.filter { $0.path == "/testImpressions/bulk"}
    }

    private func getLastImpressionsJsonHit() -> String {
        let trackRecs = tracksHits()
        return trackRecs[trackRecs.count  - 1].data!
    }

    private func getImpressionBy(testName: String) -> ImpressionsTest? {
        let hits = impressionsHits()
        for req in hits {
            var lastImpressionsHitTest: [ImpressionsTest] = []
            do {
                lastImpressionsHitTest = try buildImpressionsFromJson(content: req.data!)
            } catch {
                print("error: \(error)")
            }
            let impressions = lastImpressionsHitTest.filter { $0.testName == testName }
            if impressions.count > 0 {
                return impressions[0]
            }
        }
        return nil
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }

    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self) {
            change.till = change.since ?? 0
            return change
        }
        return nil
    }
}
