//
//  MySegmentServerErrorTest.swift
//  MySegmentServerErrorTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class MySegmentServerErrorTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    let kChangeNbInterval: Int64 = 86400
    var reqSegmentsIndex = 0
    var isFirstChangesReq = true
    var serverUrl = ""

    let sgExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "error 1"),
        XCTestExpectation(description: "error 2"),
        XCTestExpectation(description: "upd 3")
    ]
    
    override func setUp() {
        setupServer()
    }
    
    override func tearDown() {
        stopServer()
    }
    
    private func setupServer() {

        webServer = MockWebServer()
        let respData = responseSlitChanges()
        var responses = [MockedResponse]()
        for data in respData {
            responses.append(MockedResponse(code: 200, data: try? Json.encodeToJson(data)))
        }

        webServer.route(method: .get, path: "/mySegments/:user_id") { request in
            var data: String
            let index = self.reqSegmentsIndex
            var code = 200
            switch index {
            case 0:
                data = "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}]}"
            case 1, 2:
                data = ""
                code = 500
            default:
                data = "{\"mySegments\":[{ \"id\":\"id2\", \"name\":\"segment2\"}]}"
            }

            if index > 0 && index <= self.sgExp.count {
                self.sgExp[index - 1].fulfill()
            }
            self.reqSegmentsIndex += 1
            return MockedResponse(code: code, data: data)
        }

        webServer.route(method: .get, path: "/splitChanges?since=:param") { request in
            if self.isFirstChangesReq {
                self.isFirstChangesReq = false
                let change = self.responseSlitChanges()[0]
                let jsonChanges = try? Json.encodeToJson(change)
                return MockedResponse(code: 200, data: jsonChanges)
            }
            return MockedResponse(code: 200, data: "{\"splits\":[], \"since\": 9567456937865, \"till\": 9567456937869 }")
        }

        webServer.route(method: .post, path: "/testImpressions/bulk") { request in
            return MockedResponse(code: 200, data: nil)
        }
        webServer.start()
        serverUrl = webServer.url
    }
    
    private func stopServer() {
        webServer.stop()
    }

    // MARK: Test
    /// Getting changes from server and test treatments and change number
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_e"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 15
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = 21
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.targetSdkEndPoint = serverUrl
        splitConfig.targetEventsEndPoint = serverUrl
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [sdkReady], timeout: 20000)

        for i in 0..<4 {
            wait(for: [sgExp[i]], timeout: 20000)
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

    private func  responseSlitChanges() -> [SplitChange] {
        var changes = [SplitChange]()
        
        
        let c = loadSplitsChangeFile()!
        let split = c.splits![0]
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

