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
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    var notificationTemplate: String!
    let kDataField = "[NOTIFICATION_DATA]"

    let featureFlagName = "mauro_java"

    let kRefreshRate = 1

    var mySegExp: XCTestExpectation?
    var ffExp: XCTestExpectation?

    var factory: SplitFactory!

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        loadNotificationTemplate()
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
        streamingBinding?.push(message: ":keepalive")
        print("KEEP")
        wait(for: [mySegExp!, ffExp!], timeout: 5)

        let treatmentBefore = client.getTreatment(featureFlagName)

        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedUpdateSplitsNotificationGzip)
        wait(for: [sdkUpdExp], timeout: 5)

        let treatmentAfter = client.getTreatment(featureFlagName)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(treatmentBefore, "control")
        XCTAssertEqual(treatmentAfter, "off")


        print("------")
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
        streamingBinding?.push(message: ":keepalive")
        wait(for: [mySegExp!, ffExp!], timeout: 5)
        let treatmentBefore = client.getTreatment(featureFlagName)
        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedUpdateSplitsNotificationZlib)
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

    func testInstantUpdateRemove() throws {

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
        streamingBinding?.push(message: ":keepalive")
        wait(for: [mySegExp!, ffExp!], timeout: 5)
        let treatmentBefore = client.getTreatment(featureFlagName)
        mySegExp = nil
        ffExp = nil

        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedUpdateSplitsNotificationZlib)
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


    var mySegmentsHitCount = 0
    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                print("CHANGES")
                self.ffExp?.fulfill()
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                print("MY SEG")
                self.mySegExp?.fulfill()
                return self.createResponse(code: 200, json: IntegrationHelper.emptyMySegments)

            case let(urlString) where urlString.contains("auth"):
                print("AUTH")
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func createResponse(code: Int, json: String) -> TestDispatcherResponse {
        return TestDispatcherResponse(code: 200, data: Data(json.utf8))
    }


    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            print("STREM")
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func wait() {
        ThreadUtils.delay(seconds: Double(self.kRefreshRate) * 2.0)
    }

    private func loadNotificationTemplate() {
        if let template = FileHelper.readDataFromFile(sourceClass: self, name: "push_msg-segment_updV2", type: "txt") {
            notificationTemplate = template
        }
    }

    private func pushMessage(_ text: String) {
        var msg = text.replacingOccurrences(of: "\n", with: " ")
        msg = notificationTemplate.replacingOccurrences(of: kDataField, with: msg)
        streamingBinding?.push(message: msg)
    }

    private func buildFactory() -> SplitFactory {
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
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "test"))
        return builder.setApiKey(apiKey).setMatchingKey(userKey)
            .setConfig(splitConfig).build()!
    }
}
