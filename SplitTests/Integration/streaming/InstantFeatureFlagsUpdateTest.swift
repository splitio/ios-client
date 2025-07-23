//
//  InstantFeatureFlagsUpdateTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 28-Jun-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import XCTest
@testable import Split

class InstantFeatureFlagsUpdateTest: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    let sseExp = XCTestExpectation(description: "Sse conn")
    var streamingHelper: StreamingTestingHelper!

    let featureFlagName = "mauro_java"

    let kRefreshRate = 1

    var mySegExp: XCTestExpectation?
    var ffExp: XCTestExpectation?

    var factory: SplitFactory!

    var changes = ""

    var changesLoaded = false

    override func setUp() {
        changesLoaded = false
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        streamingHelper = StreamingTestingHelper()
    }

    func testInstantUpdateGzip() throws {


        factory = buildFactory()
        let client = factory.client

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp], timeout: 5)

        mySegExp = XCTestExpectation()
        ffExp = XCTestExpectation()
        streamingHelper.pushKeepalive()

        wait(for: [mySegExp!, ffExp!], timeout: 5)

        let treatmentBefore = client.getTreatment(featureFlagName)

        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        streamingHelper.pushSplitsMessage(TestingData.kEscapedUpdateSplitsNotificationGzip)
        wait(for: [sdkUpdExp], timeout: 5)

        let treatmentAfter = client.getTreatment(featureFlagName)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(treatmentBefore, "control")
        XCTAssertEqual(treatmentAfter, "off")

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testInstantUpdateZlib() throws {

        factory = buildFactory()
        let client = factory.client

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp], timeout: 5)

        mySegExp = XCTestExpectation()
        ffExp = XCTestExpectation()
        streamingHelper.pushKeepalive()
        wait(for: [mySegExp!, ffExp!], timeout: 5)
        let treatmentBefore = client.getTreatment(featureFlagName)
        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        streamingHelper.pushSplitsMessage(TestingData.kEscapedUpdateSplitsNotificationZlib)
        wait(for: [sdkUpdExp], timeout: 5)

        let treatmentAfter = client.getTreatment(featureFlagName)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(treatmentBefore, "control")
        XCTAssertEqual(treatmentAfter, "off")

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testInstantUpdateArchived() throws {
        changesLoaded = true
        loadChanges()
        factory = buildFactory()
        let client = factory.client

        let featureFlag = "NET_CORE_getTreatmentWithConfigAfterArchive"

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp], timeout: 5)

        mySegExp = XCTestExpectation()
        ffExp = XCTestExpectation()
        streamingHelper.pushKeepalive()
        // This one is failing, I assume because the split_change is not using segments (how do I fix this on the JSON?)
        wait(for: [mySegExp!, ffExp!], timeout: 5)
        let treatmentBefore = client.getTreatment(featureFlag)
        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        streamingHelper.pushSplitsMessage(TestingData.kArchivedFeatureFlagZlib)
        wait(for: [sdkUpdExp], timeout: 5)

        let treatmentAfter = client.getTreatment(featureFlag)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(treatmentBefore, "on")
        XCTAssertEqual(treatmentAfter, "control")

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }


    var mySegmentsHitCount = 0
    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                self.ffExp?.fulfill()
                if self.changesLoaded {
                    self.changesLoaded = false
                    return TestDispatcherResponse(code: 200, data: Data(self.changes.utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))
            }
            if request.isMySegmentsEndpoint() {
                self.mySegExp?.fulfill()
                return self.createResponse(code: 200, json: IntegrationHelper.emptyMySegments)
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 500)
        }
    }

    private func createResponse(code: Int, json: String) -> TestDispatcherResponse {
        return TestDispatcherResponse(code: 200, data: Data(json.utf8))
    }


    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingHelper.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingHelper.streamingBinding!
        }
    }

    private func wait() {
        ThreadUtils.delay(seconds: Double(self.kRefreshRate) * 2.0)
    }

    private func buildFactory(changeNumber: Int64 = 0) -> SplitFactory {
        let db = TestingHelper.createTestDatabase(name: "test")
        db.generalInfoDao.update(info: .splitsChangeNumber, longValue: changeNumber)
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPushRate = 999999

        let userKey = "key1"
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        return builder.setApiKey(apiKey).setMatchingKey(userKey)
            .setConfig(splitConfig).build()!
    }

    private func loadChanges() {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.splits[0].name = "NET_CORE_getTreatmentWithConfigAfterArchive"
        change?.since = 500
        change?.till = 500
        changes = (try? Json.encodeToJson(
            TargetingRulesChange(featureFlags: change!, ruleBasedSegments: RuleBasedSegmentChange(segments: [], since: -1, till: -1))
        )) ?? IntegrationHelper.emptySplitChanges
    }
}
