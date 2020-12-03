//
//  DestroyTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 16/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class DestroyTests: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    var splitChange: SplitChange?

    var trackHitCounter = 0
    var impressionsHitCount = 0
    var splitChangesHitCount = 0
    var mySegmentsHitCount = 0
    var serverUrl = ""
    var lastChangeNumber = 1

    var impressions: [Impression]!
    var events: [EventDTO]!
    
    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        impressions = [Impression]()
        events = [EventDTO]()
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {
        webServer = MockWebServer()

        webServer.route(method: .get, path: "/mySegments/:user_id") { request in
            self.mySegmentsHitCount+=1
            return MockedResponse(code: 200, data: IntegrationHelper.emptyMySegments)
        }

        webServer.route(method: .get, path: "/splitChanges?since=:param") { request in

            self.splitChangesHitCount+=1
            let since = self.lastChangeNumber
            return MockedResponse(code: 200,
                                  data: self.splitChangesHitCount == 1 ?
                                    try? Json.encodeToJson(self.splitChange)
                                    : IntegrationHelper.emptySplitChanges(since: since, till: since))
        }

        webServer.route(method: .post, path: "/events/bulk") { request in
            self.trackHitCounter+=1
            if let data = request.data {
                if let e = try? IntegrationHelper.buildEventsFromJson(content: data) {
                    self.events.append(contentsOf: e)
                }
            }
            return MockedResponse(code: 200, data: nil)
        }

        webServer.route(method: .post, path: "/testImpressions/bulk") { request in
            self.impressionsHitCount+=1
            if let data = request.data {
                if let tests = try? IntegrationHelper.buildImpressionsFromJson(content: data) {
                    for test in tests {
                        self.impressions.append(contentsOf: test.keyImpressions)
                    }
                }
            }
            return MockedResponse(code: 200, data: nil)
        }

        webServer.start()
        serverUrl =  webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }
    
    func testDestroy() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_h"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        let eventType = "testEvent"
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 5
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = 5
        splitConfig.impressionsChunkSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 100
        splitConfig.eventsQueueSize = 1000
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory?.client
        let manager = factory?.manager
        let splitName = "FACUNDO_TEST"
        
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

        let treatmentBeforeDestroy = client?.getTreatment(splitName)
        let treatmentWithConfigBeforeDestroy = client?.getTreatmentWithConfig(splitName)
        let treatmentsBeforeDestroy = client?.getTreatments(splits: [splitName], attributes: nil)
        let treatmentsWithConfigBeforeDestroy = client?.getTreatmentsWithConfig(splits: [splitName], attributes: nil)
        let trackBeforeDestroy = client?.track(eventType: eventType, value: 1.0)
        let splitBeforeDestroy = manager?.split(featureName: splitName)
        let splitCountBeforeDestroy = manager?.splits.count
        let splitNamesCountBeforeDestroy = manager?.splitNames.count

        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        sleep(15)

        let trackHitCounterBeforeDestroy = trackHitCounter
        let impressionsHitCountBeforeDestroy = impressionsHitCount
        let splitChangesHitCountBeforeDestroy = splitChangesHitCount
        let mySegmentsHitCountBeforeDestroy = mySegmentsHitCount

        clearCounters()

        sleep(10)

        let trackHitCounterAfterDestroy = trackHitCounter
        let impressionsHitCountAfterDestroy = impressionsHitCount
        let splitChangesHitCountAfterDestroy = splitChangesHitCount
        let mySegmentsHitCountAfterDestroy = mySegmentsHitCount

        let treatmentAfterDestroy = client?.getTreatment(splitName)
        let treatmentWithConfigAfterDestroy = client?.getTreatmentWithConfig(splitName)
        let treatmentsAfterDestroy = client?.getTreatments(splits: [splitName], attributes: nil)
        let treatmentsWithConfigAfterDestroy = client?.getTreatmentsWithConfig(splits: [splitName], attributes: nil)
        let trackAfterDestroy = client?.track(eventType: trafficType, value: 1.0)
        let splitAfterDestroy = manager?.split(featureName: splitName)
        let splitCountAfterDestroy = manager?.splits.count
        let splitNamesAfterCountBDestroy = manager?.splitNames.count

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual("off", treatmentBeforeDestroy)
        XCTAssertEqual("off", treatmentWithConfigBeforeDestroy?.treatment)
        XCTAssertEqual("off", treatmentsBeforeDestroy?[splitName])
        XCTAssertEqual("off", treatmentsWithConfigBeforeDestroy?[splitName]?.treatment)
        XCTAssertEqual(true, trackBeforeDestroy)
        XCTAssertEqual(splitName, splitBeforeDestroy?.name)
        XCTAssertEqual(30, splitCountBeforeDestroy)
        XCTAssertEqual(30, splitNamesCountBeforeDestroy)

        XCTAssertEqual(SplitConstants.control, treatmentAfterDestroy)
        XCTAssertEqual(SplitConstants.control, treatmentWithConfigAfterDestroy?.treatment)
        XCTAssertEqual(SplitConstants.control, treatmentsAfterDestroy?[splitName])
        XCTAssertEqual(SplitConstants.control, treatmentsWithConfigAfterDestroy?[splitName]?.treatment)
        XCTAssertEqual(false, trackAfterDestroy)
        XCTAssertNil(splitAfterDestroy)
        XCTAssertEqual(0, splitCountAfterDestroy)
        XCTAssertEqual(0, splitNamesAfterCountBDestroy)

        XCTAssertTrue(trackHitCounterBeforeDestroy > 0)
        XCTAssertTrue(impressionsHitCountBeforeDestroy > 0)
        XCTAssertTrue(splitChangesHitCountBeforeDestroy > 0)
        XCTAssertTrue(mySegmentsHitCountBeforeDestroy > 0)

        XCTAssertEqual(0, trackHitCounterAfterDestroy)
        XCTAssertEqual(0, impressionsHitCountAfterDestroy)
        XCTAssertEqual(0, splitChangesHitCountAfterDestroy)
        XCTAssertEqual(0, mySegmentsHitCountAfterDestroy)

        XCTAssertEqual(4, impressions.count)
        XCTAssertEqual(1, events.count)

        XCTAssertEqual(matchingKey, impressions?[0].keyName)
        XCTAssertEqual("off", impressions?[0].treatment)

        XCTAssertEqual(matchingKey, impressions?[3].keyName)
        XCTAssertEqual("off", impressions?[3].treatment)

        XCTAssertEqual(trafficType, events?[0].trafficTypeName)
        XCTAssertEqual(1.0, events?[0].value)
        XCTAssertEqual(eventType, events?[0].eventTypeId)
    }

    private func clearCounters() {
        trackHitCounter = 0
        impressionsHitCount = 0
        splitChangesHitCount = 0
        mySegmentsHitCount = 0
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }

    private func loadSplitChangeFile(name fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self) {
            lastChangeNumber = Int(change.till ?? 0)
            return change
        }
        return nil
    }
}
