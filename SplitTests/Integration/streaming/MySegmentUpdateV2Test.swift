//
//  MySegmentUpdateV2Test.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import XCTest
@testable import Split

class MySegmentUpdateV2Test: XCTestCase {
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    let sseExp = XCTestExpectation(description: "Sse conn")
    var notificationTemplate: String!
    let kDataField = "[NOTIFICATION_DATA]"

    var mySegHitCount = 0

    let kRefreshRate = 1

    var mySegExp: XCTestExpectation!

    var testFactory: TestSplitFactory!

    override func setUp() {

        loadNotificationTemplate()
    }

    func testMySegmentsUpdate() throws {
        let userKey = "key1"
        testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        mySegExp = XCTestExpectation()
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client
        let db = testFactory.splitDatabase

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

        streamingBinding?.push(message: ":keepalive")

        wait(for: [mySegExp], timeout: 5)

        // Unbounded fetch notification should trigger my segments
        // refresh on synchronizer
        // Set count to 0 to start counting hits
        syncSpy.forceMySegmentsCalledCount = 0
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kUnboundedNotification)
        wait(for: [sdkUpdExp], timeout: 5)

        // Should not trigger any fetch to my segments because
        // this payload doesn't have "key1" enabled

        pushMessage(TestingData.kEscapedBoundedNotificationZlib)

        // Pushed key list message. Key 1 should add a segment
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedKeyListNotificationGzip)
        wait(for: [sdkUpdExp], timeout: 5)

        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kSegmentRemovalNotification)
        wait(for: [sdkUpdExp], timeout: 5)

        let segmentEntity = db.mySegmentsDao.getBy(userKey: testFactory.userKey)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(1, syncSpy.forceMySegmentsSyncCount[userKey] ?? 0)
        XCTAssertEqual(1, segmentEntity.filter { $0 == "new_segment_added" }.count)
        XCTAssertEqual(0, segmentEntity.filter { $0 == "segment1" }.count)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testMySegmentsUpdateBounded() throws {
        mySegExp = XCTestExpectation()
        let userKey = "603516ce-1243-400b-b919-0dce5d8aecfd"
        testFactory = TestSplitFactory(userKey: userKey)
        testFactory.createHttpClient(dispatcher: buildTestDispatcher(), streamingHandler: buildStreamingHandler())
        try testFactory.buildSdk()
        let syncSpy = testFactory.synchronizerSpy
        let client = testFactory.client

        let sdkReadyExp = XCTestExpectation(description: "SDK READY Expectation")
        var sdkUpdExp = XCTestExpectation(description: "SDK UPDATE Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExp.fulfill()
        }

        client.on(event: SplitEvent.sdkUpdated) {
            sdkUpdExp.fulfill()
        }

        // Wait for hitting my segments two times (sdk ready and full sync after streaming connection)
        wait(for: [sdkReadyExp, sseExp], timeout: 15)

        streamingBinding?.push(message: ":keepalive")

        wait(for: [mySegExp], timeout: 5)

        // Unbounded fetch notification should trigger my segments
        // refresh on synchronizer
        // Set count to 0 to start counting hits
        syncSpy.forceMySegmentsCalledCount = 0
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kUnboundedNotification)
        wait(for: [sdkUpdExp], timeout: 5)


        // Pushed key list message. Key 1 should add a segment
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedBoundedNotificationGzip)
        wait(for: [sdkUpdExp], timeout: 5)

        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedBoundedNotificationZlib)
        wait(for: [sdkUpdExp], timeout: 5)

        // Should trigger unbounded
        sdkUpdExp = XCTestExpectation()
        pushMessage(TestingData.kEscapedBoundedNotificationMalformed)
        wait(for: [sdkUpdExp], timeout: 5)

        // Hits are not asserted because tests will fail if expectations are not fulfilled
        XCTAssertEqual(4, syncSpy.forceMySegmentsSyncCount[userKey] ?? 0)

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
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 100, till: 100).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                self.mySegmentsHitCount+=1
                if self.mySegmentsHitCount == 2 {
                    self.mySegExp.fulfill()
                }
                return self.createResponse(code: 200, json: self.updatedSegments(index: self.mySegmentsHitCount))

            case let(urlString) where urlString.contains("auth"):
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func createResponse(code: Int, json: String) -> TestDispatcherResponse {
        return TestDispatcherResponse(code: 200, data: Data(json.utf8))
    }

    private func updatedSegments(index: Int) -> String {
        var resp = [String]()
        for i in (1..<index) {
            resp.append("{ \"id\":\"id\(i)\", \"name\":\"segment\(i)\"}")
        }
        return "{\"mySegments\":[\(resp.joined(separator: ","))]}"
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
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
}
