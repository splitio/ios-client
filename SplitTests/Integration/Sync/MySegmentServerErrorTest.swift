//
//  MySegmentServerErrorTest.swift
//  MySegmentServerErrorTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class MySegmentServerErrorTest: XCTestCase {
    let kNeverRefreshRate = 9999999
    let kChangeNbInterval: Int64 = 86400
    var reqSegmentsIndex = 0
    var isFirstChangesReq = true
    var serverUrl = "localhost"
    var lastChangeNumber = 0

    let sgExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "error 1"),
        XCTestExpectation(description: "error 2"),
        XCTestExpectation(description: "upd 3"),
    ]

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
        return { request in
            if request.isSplitEndpoint() {
                if self.isFirstChangesReq {
                    self.isFirstChangesReq = false
                    let change = self.responseSlitChanges()[0]
                    self.lastChangeNumber = Int(change.till)
                    let jsonChanges = try? Json.encodeToJson(TargetingRulesChange(
                        featureFlags: change,
                        ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1)))
                    return TestDispatcherResponse(code: 200, data: Data(jsonChanges!.utf8))
                }
                let since = self.lastChangeNumber
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: since, till: since).utf8))
            }
            if request.isMySegmentsEndpoint() {
                var data: String
                let index = self.reqSegmentsIndex
                var code = 200
                switch index {
                case 0:
                    data = IntegrationHelper.buildSegments(regular: ["segment1"])
                case 1, 2:
                    data = ""
                    code = 500
                default:
                    data = IntegrationHelper.buildSegments(regular: ["segment2"])
                }

                if index > 0 && index <= self.sgExp.count {
                    self.sgExp[index - 1].fulfill()
                }
                self.reqSegmentsIndex += 1
                return TestDispatcherResponse(code: code, data: Data(data.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
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

    // MARK: Test

    /// Getting changes from server and test treatments and change number
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_e"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")

        let splitConfig = SplitClientConfig()
        splitConfig.streamingEnabled = false
        splitConfig.featuresRefreshRate = 15
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = 21
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()

        let key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "GralIntegrationTest"))
        _ = builder.setHttpClient(httpClient)
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()

        let client = factory!.client

        var sdkReadyFired = false

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        wait(for: [sdkReady], timeout: 20)

        for i in 0 ..< 4 {
            wait(for: [sgExp[i]], timeout: 20)
            treatments.append(client.getTreatment("test_feature"))
        }

        XCTAssertTrue(sdkReadyFired)

        XCTAssertEqual("on_s1", treatments[0])
        XCTAssertEqual("on_s1", treatments[1])
        XCTAssertEqual("on_s1", treatments[2])
        XCTAssertEqual("on_s2", treatments[3])

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
}
