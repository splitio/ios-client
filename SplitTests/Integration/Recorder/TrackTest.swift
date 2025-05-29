//
//  TrackTest.swift
//  TrackTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class TrackTest: XCTestCase {
    let kNeverRefreshRate = 9999999
    let kChangeNbInterval: Int64 = 86400
    var reqTrackIndex = 0
    var serverUrl = "localhost"

    var trackHits = [[EventDTO]]()

    let trExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "error 1"),
        XCTestExpectation(description: "error 2"),
        XCTestExpectation(description: "error 3"),
        XCTestExpectation(description: "upd 4"),
        XCTestExpectation(description: "upd 5"),
    ]

    let queue = DispatchQueue(label: "ios.split.itest.track", attributes: .concurrent)

    var httpClient: HttpClient!
    var streamingBinding: TestStreamResponseBinding?

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        let respData = responseSlitChanges()
        var responses = [TestDispatcherResponse]()
        for data in respData {
            responses.append(TestDispatcherResponse(code: 200, data: Data(try! Json.encodeToJson(data).utf8)))
        }

        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 9999999, till: 9999999).utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                var code = 0
                self.queue.sync {
                    let index = self.getAndIncrement()
                    print("Hit: \(index)")
                    if index > 0, index < 4 {
                        code = 500
                    } else {
                        let data = try? IntegrationHelper
                            .buildEventsFromJson(content: request.body!.stringRepresentation)
                        self.trackHits.append(data!)
                        code = 200
                    }

                    if index < 6 {
                        self.trExp[index].fulfill()
                    }
                }
                return TestDispatcherResponse(code: code)
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

    // MARK: Test

    /// Getting changes from server and test treatments and change number
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_d"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var trackCounts = [Int]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")

        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = kNeverRefreshRate
        splitConfig.segmentsRefreshRate = kNeverRefreshRate
        splitConfig.impressionRefreshRate = kNeverRefreshRate
        splitConfig.eventsPushRate = 5
        splitConfig.eventsPerPush = 5
        splitConfig.eventsFirstPushWindow = 5
        splitConfig.eventsQueueSize = 10000
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "TrackTest"))
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig)
            .build()

        let client = factory!.client

        var sdkReadyFired = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        wait(for: [sdkReady], timeout: 20)

        for i in 0 ..< 5 {
            _ = client.track(trafficType: "custom", eventType: "event1", value: Double(i), properties: ["value": i])
        }
        wait(for: [trExp[0]], timeout: 10)
        trackCounts.append(trackHits.count)

        for i in 0 ..< 5 {
            _ = client.track(trafficType: "custom", eventType: "event2", value: Double(i), properties: ["value": i])
        }
        wait(for: [trExp[1]], timeout: 10)
        trackCounts.append(trackHits.count)

        for i in 0 ..< 5 {
            _ = client.track(trafficType: "custom", eventType: "event3", value: Double(i), properties: ["value": i])
        }
        wait(for: [trExp[2], trExp[3]], timeout: 40)
        trackCounts.append(trackHits.count)

        wait(for: [trExp[4], trExp[5]], timeout: 40)
        trackCounts.append(trackHits.count)

        XCTAssertTrue(sdkReadyFired)

        // Testing that failed events are sent
        // in third attempt
        XCTAssertEqual(1, trackCounts[0])
        XCTAssertEqual(1, trackCounts[1])
        XCTAssertEqual(1, trackCounts[2])
        XCTAssertEqual(3, trackCounts[3])

        let e1 = findEvent(type: "event1", value: 0.0)
        let e2 = findEvent(type: "event2", value: 2.0)
        let e3 = findEvent(type: "event3", value: 3.0)

        XCTAssertEqual("custom", e1?.trafficTypeName)
        XCTAssertEqual(0.0, e1?.value)
        XCTAssertEqual("event1", e1?.eventTypeId)
        XCTAssertEqual(0, e1?.properties?["value"] as? Int ?? -1)

        XCTAssertEqual("custom", e2?.trafficTypeName)
        XCTAssertEqual(2.0, e2?.value)
        XCTAssertEqual("event2", e2?.eventTypeId)
        XCTAssertEqual(2, e2?.properties?["value"] as? Int ?? -1)

        XCTAssertEqual("custom", e3?.trafficTypeName)
        XCTAssertEqual(3.0, e3?.value)
        XCTAssertEqual("event3", e3?.eventTypeId)
        XCTAssertEqual(3, e3?.properties?["value"] as? Int ?? -1)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
        factory = nil
    }

    private func responseSlitChanges() -> [SplitChange] {
        var changes = [SplitChange]()

        let c = loadSplitsChangeFile()!
        let split = c.splits[0]
        let inSegmentOneCondition = inSegmentCondition(name: "segment1")
        inSegmentOneCondition.partitions![0].treatment = "on_s1"
        inSegmentOneCondition.partitions![0].size = 100
        inSegmentOneCondition.partitions![1].treatment = "off_s1"
        inSegmentOneCondition.partitions![1].size = 0

        let inSegmentTwoCondition = inSegmentCondition(name: "segment2")
        inSegmentTwoCondition.partitions![0].treatment = "on_s2"
        inSegmentTwoCondition.partitions![0].size = 100
        inSegmentTwoCondition.partitions![1].treatment = "off_s2"
        inSegmentTwoCondition.partitions![1].size = 0

        split.conditions?.insert(inSegmentOneCondition, at: 0)
        split.conditions?.insert(inSegmentTwoCondition, at: 0)

        changes.append(c)

        return changes
    }

    private func inSegmentCondition(name: String) -> Condition {
        let condition = Condition()
        let matcherGroup = MatcherGroup()
        let matcher = Matcher()
        let matcherData = UserDefinedSegmentMatcherData()
        condition.partitions = [Partition(), Partition()]
        matcherData.segmentName = name
        matcherGroup.matcherCombiner = .and
        condition.conditionType = .whitelist
        condition.matcherGroup = matcherGroup
        matcher.matcherType = .inSegment
        matcher.userDefinedSegmentMatcherData = matcherData
        matcherGroup.matchers = [matcher]

        return condition
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        return FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_int_test")
    }

    private func findEvent(type: String, value: Double) -> EventDTO? {
        if trackHits.isEmpty { return nil }
        var e: EventDTO?
        var i = 0
        while e == nil, i < trackHits.count {
            e = trackHits[i].first(where: { $0.eventTypeId == type && $0.value == value })
            i += 1
        }
        return e
    }

    private func getAndIncrement() -> Int {
        var i = 0
        DispatchQueue.test.sync {
            i = self.reqTrackIndex
            self.reqTrackIndex += 1
        }
        return i
    }
}
