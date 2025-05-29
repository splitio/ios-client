//
//  DestroyTests.swift
//  SplitIntegrationTests
//
//  Created by Javier L. Avrudsky on 16/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class DestroyTests: XCTestCase {
    let kNeverRefreshRate = 9999999
    var splitChange: TargetingRulesChange?

    var trackHitCounter = 0
    var impressionsHitCount = 0
    var splitChangesHitCount = 0
    var mySegmentsHitCount = 0
    var serverUrl = "localhost"
    var lastChangeNumber = 1

    var impressions: [KeyImpression]!
    var events: [EventDTO]!
    var httpClient: HttpClient!
    var streamingBinding: TestStreamResponseBinding?

    override func setUp() {
        if splitChange == nil {
            splitChange = loadSplitsChangeFile()
        }
        impressions = [KeyImpression]()
        events = [EventDTO]()

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                self.splitChangesHitCount += 1
                let since = self.lastChangeNumber
                return TestDispatcherResponse(
                    code: 200,
                    data: self.splitChangesHitCount == 1 ?
                        Data(try! Json.encodeToJson(self.splitChange).utf8)
                        :
                        Data(
                            IntegrationHelper
                                .emptySplitChanges(since: since, till: since).utf8))
            }

            if request.isMySegmentsEndpoint() {
                self.mySegmentsHitCount += 1
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.impressionsHitCount += 1
                if let data = request.body {
                    if let tests = try? IntegrationHelper.buildImpressionsFromJson(content: data.stringRepresentation) {
                        for test in tests {
                            self.impressions.append(contentsOf: test.keyImpressions)
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                self.trackHitCounter += 1
                if let data = request.body {
                    if let e = try? IntegrationHelper.buildEventsFromJson(content: data.stringRepresentation) {
                        self.events.append(contentsOf: e)
                    }
                }
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }

//    private func buildTestDispatcher() -> HttpClientTestDispatcher {
//
//        return { request in
//            switch request.url.absoluteString {
//            case let(urlString) where urlString.contains("splitChanges"):
//                self.splitChangesHitCount+=1
//                let since = self.lastChangeNumber
//                return TestDispatcherResponse(code: 200,
//                                      data: self.splitChangesHitCount == 1 ?
//                                              Data(try! Json.encodeToJson(self.splitChange).utf8)
//                                              : Data(IntegrationHelper.emptySplitChanges(since: since, till: since).utf8))
//
//            case let(urlString) where urlString.contains("mySegments"):
//                self.mySegmentsHitCount+=1
//                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
//
//            case let(urlString) where urlString.contains("auth"):
//                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
//
//            case let(urlString) where urlString.contains("testImpressions/bulk"):
//                self.impressionsHitCount+=1
//                if let data = request.body {
//                    if let tests = try? IntegrationHelper.buildImpressionsFromJson(content: data.stringRepresentation) {
//                        for test in tests {
//                            self.impressions.append(contentsOf: test.keyImpressions)
//                        }
//                    }
//                }
//                return TestDispatcherResponse(code: 200)
//
//            case let(urlString) where urlString.contains("events/bulk"):
//                self.trackHitCounter+=1
//                if let data = request.body {
//                    if let e = try? IntegrationHelper.buildEventsFromJson(content: data.stringRepresentation) {
//                        self.events.append(contentsOf: e)
//                    }
//                }
//                return TestDispatcherResponse(code: 200)
//
//            default:
//                return TestDispatcherResponse(code: 500)
//            }
//        }
//    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }

    func testDestroy() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_h"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "account"
        let eventType = "testEvent"

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 5
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = 5
        splitConfig.impressionsChunkSize = 100
        splitConfig.eventsPushRate = 5
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.eventsPerPush = 100
        splitConfig.eventsQueueSize = 1000
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.logLevel = .verbose
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "GralIntegrationTest"))
        _ = builder.setHttpClient(httpClient)
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

        wait(for: [sdkReadyExpectation], timeout: 10)

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
        sleep(1)

        let trackHitCounterBeforeDestroy = trackHitCounter
        let impressionsHitCountBeforeDestroy = impressionsHitCount
        let splitChangesHitCountBeforeDestroy = splitChangesHitCount
        let mySegmentsHitCountBeforeDestroy = mySegmentsHitCount

        clearCounters()

        sleep(1)

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
        XCTAssertEqual(33, splitCountBeforeDestroy)
        XCTAssertEqual(33, splitNamesCountBeforeDestroy)

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

    private func loadSplitsChangeFile() -> TargetingRulesChange? {
        return loadSplitChangeFile(name: "splitchanges_1")
    }

    private func loadSplitChangeFile(name fileName: String) -> TargetingRulesChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            lastChangeNumber = Int(change.featureFlags.till)
            return change
        }
        return nil
    }
}
