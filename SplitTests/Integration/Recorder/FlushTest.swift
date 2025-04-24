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
    var httpClient: HttpClient!
    var splitChange: TargetingRulesChange?
    var serverUrl = "localhost"
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    var trackRequestData = [String]()
    var impressionsRequestData = [String]()

    var impExp: XCTestExpectation?
    var trackExp: XCTestExpectation?
    
    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        trackRequestData = [String]()
        impressionsRequestData = [String]()
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }
    
    func test() throws {
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
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()
        
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
        
        wait(for: [sdkReadyExpectation], timeout: 40)

        for i in 0..<10 {
            sleep(1)
            _ = client?.getTreatment("FACUNDO_TEST")
            _ = client?.getTreatment("Test_Save_1")
            _ = client?.getTreatment("NO_EXISTING_FEATURE_\(i)")
        }

        for i in 0..<100 {
            _ = client?.track(eventType: "account", value: Double(i))
        }

        impExp = XCTestExpectation()
        trackExp = XCTestExpectation()
        client?.flush()
        wait(for: [impExp!, trackExp!], timeout: 5)


        let event99 = getTrackEventBy(value: 99.0)
        let event100 = getTrackEventBy(value: 100.0)

        let impression1 = getImpressionBy(testName: "FACUNDO_TEST")
        let impression2 = getImpressionBy(testName: "NO_EXISTING_FEATURE_1")

        XCTAssertTrue(sdkReadyFired)
        XCTAssertFalse(timeOutFired)
        XCTAssertEqual(10, trackRequestData.count)
        XCTAssertNotNil(event99)
        XCTAssertNil(event100)
        XCTAssertNotNil(impression1)
        XCTAssertNil(impression2)
        let semaphore = DispatchSemaphore(value: 0)
        client?.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    // MARK: Tracks Hits
    private func buildEventsFromJson(content: String) throws -> [EventDTO] {
        return try Json.dynamicDecodeFrom(json: content, to: [EventDTO].self)
    }

    private func getTrackEventBy(value: Double) -> EventDTO? {
        let hits = trackRequestData
        for data in hits {
            var lastEventHitEvents: [EventDTO] = []
            do {
                lastEventHitEvents = try buildEventsFromJson(content: data)
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
        return try Json.decodeFrom(json: content, to: [ImpressionsTest].self)
    }

    private func getImpressionBy(testName: String) -> ImpressionsTest? {
        let hits = impressionsRequestData
        for data in hits {
            var lastImpressionsHitTest: [ImpressionsTest] = []
            do {
                lastImpressionsHitTest = try buildImpressionsFromJson(content:data)
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

    private func loadSplitsChangeFile() -> TargetingRulesChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }

    private func loadSplitChangeFile(name fileName: String) -> TargetingRulesChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let targetingRulesChange = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            let flagsChange = targetingRulesChange.featureFlags
            flagsChange.till = Int64(Int(flagsChange.since))
            return TargetingRulesChange(featureFlags: flagsChange, ruleBasedSegments: targetingRulesChange.ruleBasedSegments)
        }
        return nil
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(self.splitChange).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse(delay: 1).utf8))
            }
            if request.isEventsEndpoint() {
                self.trackRequestData.append(request.body?.stringRepresentation ?? "{}")
                if self.nextTrackHit() >= 10 {
                    self.trackExp?.fulfill()
                }
                return TestDispatcherResponse(code: 200)
            }
            if request.isImpressionsEndpoint() {
                if self.nextImpressionHit() >= 1 {
                    self.impExp?.fulfill()
                }
                self.impressionsRequestData.append(request.body?.stringRepresentation ?? "{}")
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    var trackHitCount = 0
    func nextTrackHit() -> Int {
        trackHitCount+=1
        return trackHitCount
    }

    var impressionHitCount = 0
    func nextImpressionHit() -> Int {
        impressionHitCount+=1
        return impressionHitCount
    }
}
