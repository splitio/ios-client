//
//  MySegmentUpdatedTest.swift
//  MySegmentUpdatedTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class MySegmentUpdatedTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    let kChangeNbInterval: Int64 = 86400
    var reqSegmentsIndex = 0
    var isFirstChangesReq = true
    var serverUrl = ""

    let sgExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "upd 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    var impressions = [String: Impression]()
    
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
            let index = self.getAndIncrement()
            switch index {
            case 1:
                data = "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}]}"
            case 2:
                data = "{\"mySegments\":[{ \"id\":\"id2\", \"name\":\"segment2\"}]}"
            default:
                data = "{\"mySegments\":[]}"
            }

            if index > 0 && index <= self.sgExp.count {
                self.sgExp[index - 1].fulfill()
            }
            return MockedResponse(code: 200, data: data)
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
            self.impHit = try? IntegrationHelper.impressionsFromHit(request: request)
            if self.addImpressions(tests: self.impHit) {
                self.impExp.fulfill()
            }
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
    func testSegments() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3_c"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var treatments = [String]()
        let splitName = "test_feature"

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 50
        splitConfig.segmentsRefreshRate = 5
        splitConfig.impressionRefreshRate = splitConfig.segmentsRefreshRate * 6 + 1
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.serviceEndpoints = ServiceEndpoints.builder()
        .set(sdkEndpoint: serverUrl).set(eventsEndpoint: serverUrl).build()
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        var factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }

        wait(for: [sdkReady], timeout: 20)

        for i in 0..<4 {
            wait(for: [sgExp[i]], timeout: 10)
            treatments.append(client.getTreatment(splitName))
        }

        wait(for: [impExp], timeout: 40)

        XCTAssertTrue(sdkReadyFired)

        XCTAssertEqual("no", treatments[0])
        XCTAssertEqual("on_s1", treatments[1])
        XCTAssertEqual("on_s2", treatments[2])
        XCTAssertEqual("no", treatments[3])

        XCTAssertEqual(1, impHit?.count)
        XCTAssertEqual(4, impHit?[0].keyImpressions.count)
        let imp0 = impressions[IntegrationHelper.buildImpressionKey(key: matchingKey, splitName: splitName, treatment: "no")]
        let imp1 = impressions[IntegrationHelper.buildImpressionKey(key: matchingKey, splitName: splitName, treatment: "on_s1")]
        let imp2 = impressions[IntegrationHelper.buildImpressionKey(key: matchingKey, splitName: splitName, treatment: "on_s2")]

        XCTAssertEqual("no", imp0?.treatment)
        XCTAssertEqual("on_s1", imp1?.treatment)
        XCTAssertEqual("on_s2", imp2?.treatment)

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

    private func getAndIncrement() -> Int {
        var i = 0;
        DispatchQueue.global().sync {
            i = self.reqSegmentsIndex
            self.reqSegmentsIndex+=1
        }
        return i
    }

    private func addImpressions(tests: [ImpressionsTest]?) -> Bool {
        var res: Bool = false
        DispatchQueue.global().sync {
            if let tests = tests {
                for test in tests {
                    for imp in test.keyImpressions {
                        //if imp.keyName! == "CUSTOMER_ID" {
                            self.impressions[IntegrationHelper.buildImpressionKey(key: imp.keyName!, splitName: test.testName, treatment: imp.treatment!)] = imp
                            res = true
                        //}
                    }
                }
            }
        }
        return res
    }
}
