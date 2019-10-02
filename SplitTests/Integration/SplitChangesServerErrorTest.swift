//
//  SplitChangesServerErrorTest.swift
//  SplitChangesServerErrorTest
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitChangesServerErrorTest: XCTestCase {
    
    let kNeverRefreshRate = 9999999
    var webServer: MockWebServer!
    let kChangeNbInterval: Int64 = 86400
    var reqChangesIndex = 0

    let spExp = [
        XCTestExpectation(description: "upd 0"),
        XCTestExpectation(description: "error 1"),
        XCTestExpectation(description: "upd 2"),
        XCTestExpectation(description: "upd 3")
    ]

    let impExp = XCTestExpectation(description: "impressions")

    var impHit: [ImpressionsTest]?
    
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
        responses.append(MockedResponse(code: 200, data: try? Json.encodeToJson(respData[0])))
        responses.append(MockedResponse(code: 500))
        responses.append(MockedResponse(code: 500))
        responses.append(MockedResponse(code: 200, data: try? Json.encodeToJson(respData[1])))


        webServer.routeGet(path: "/mySegments/:user_id",
                           data: "{\"mySegments\":[{ \"id\":\"id1\", \"name\":\"segment1\"}, "
                            + "{ \"id\":\"id1\", \"name\":\"segment2\"}]}")

        webServer.route(method: .get, path: "/splitChanges?since=:param") { request in
            let index = self.reqChangesIndex
            if index < self.spExp.count {
                if self.reqChangesIndex > 0 {
                    self.spExp[index - 1].fulfill()
                }
                self.reqChangesIndex += 1
                return responses[index]
            } else if index == self.spExp.count {
                self.spExp[index - 1].fulfill()
            }
            return MockedResponse(code: 200, data: "{\"splits\":[], \"since\": 9567456937865, \"till\": 9567456937869 }")
        }

        webServer.routePost(path: "/testImpressions/bulk")

        webServer.start()
    }
    
    private func stopServer() {
        webServer.stop()
    }

    // MARK: Test
    /// Getting changes from server and test treatments and change number
    func test() throws {
        let apiKey = "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
        let matchingKey = "CUSTOMER_ID"
        let trafficType = "client"
        var treatments = [String]()

        let sdkReady = XCTestExpectation(description: "SDK READY Expectation")
        
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 5
        splitConfig.impressionRefreshRate = kNeverRefreshRate
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.trafficType = trafficType
        splitConfig.targetSdkEndPoint = "http://localhost:8080"
        splitConfig.targetEventsEndPoint = "http://localhost:8080"
        
        let key: Key = Key(matchingKey: matchingKey, bucketingKey: nil)
        let builder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(apiKey).setKey(key).setConfig(splitConfig).build()
        
        let client = factory!.client

        var sdkReadyFired = false
        
        client.on(event: SplitEvent.sdkReady) {
            sdkReadyFired = true
            sdkReady.fulfill()
        }
        
        wait(for: [sdkReady], timeout: 20000)

        for i in 0..<4 {
            wait(for: [spExp[i]], timeout: 20000)
            treatments.append(client.getTreatment("test_feature"))
        }

        XCTAssertTrue(sdkReadyFired)

        XCTAssertEqual("on_0", treatments[0])
        XCTAssertEqual("on_0", treatments[1])
        XCTAssertEqual("on_0", treatments[2])
        XCTAssertEqual("off_1", treatments[3])
    }

    private func  responseSlitChanges() -> [SplitChange] {
        var changes = [SplitChange]()


        var prevChangeNumber: Int64 = 0
        for i in 0..<2 {
            let c = loadSplitsChangeFile()!
            if prevChangeNumber != 0 {
                c.since = prevChangeNumber
                c.till = prevChangeNumber + kChangeNbInterval
            }
            prevChangeNumber = c.till!
            let split = c.splits![0]
            let even = ((i + 2) % 2 == 0)
            split.changeNumber = prevChangeNumber
            split.conditions![0].partitions![0].treatment = "on_\(i)"
            split.conditions![0].partitions![0].size = (even ? 100 : 0)
            split.conditions![0].partitions![1].treatment = "off_\(i)"
            split.conditions![0].partitions![1].size = (even ? 0 : 100)
            changes.append(c)
        }
        return changes
    }

    private func loadSplitsChangeFile() -> SplitChange? {
        return FileHelper.loadSplitChangeFile(sourceClass: self, fileName: "splitchanges_int_test")
    }

    private func impressionsHits() -> [ClientRequest] {
        return webServer.receivedRequests.filter { $0.path == "/testImpressions/bulk"}
    }

    private func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.encodeFrom(json: content, to: [ImpressionsTest].self)
    }

    private func impressionsFromHit(request: ClientRequest) throws -> [ImpressionsTest] {
        return try buildImpressionsFromJson(content: request.data!)
    }
}

