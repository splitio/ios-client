//
//  MultiClientEvaluation.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MultiClientEvaluationTest: XCTestCase {

    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    var defaultKey = IntegrationHelper.dummyUserKey
    var key1 = "key_1"
    var key2 = "key_2"
    var key3 = "key_3"

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.global())

    struct Attr {
        static let numValue = "num_value"
        static let strValue = "str_value"
        static let numValueA = "num_value_a"
        static let strValueA = "str_value_a"
    }

    let attrValues: [String: Any] = [
        Attr.numValue: 10,
        Attr.strValue: "yes",
        Attr.numValueA: 20,
        Attr.strValueA: "no"
    ]

    var cachedSplit: Split!

    override func setUp() {
        cachedSplit = buildSplitEntity()
    }

    func testOne() {
        var clients = [String: SplitClient]()
        var readyExps = [String: XCTestExpectation]()
        var cache = [String: Bool]()

        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: cachedSplit)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = true

        let cacheReadyExp = XCTestExpectation()

        let key: Key = Key(matchingKey: defaultKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        clients[defaultKey] = factory.client

        // Using all new API methods
        clients[key1] = factory.client(key: Key(matchingKey: key1))
        clients[key2] = factory.client(matchingKey: "key2")
        clients[key3] = factory.client(matchingKey: "key1", bucketingKey: "buckKey")

        for (key, client) in clients {
            clients[key]?.on(event: SplitEvent.sdkReadyFromCache) {
                cacheReadyExp.fulfill()
                print("Ready from cache")
            }

            clients[key]?.on(event: SplitEvent.sdkReady) {
                cacheReadyExp.fulfill()
                print("Ready from cache")
            }
        }

        wait(for: [cacheReadyExp], timeout: 5)

        let evalAfterInit = splitClient.getTreatment(splitName)

        _ = splitClient.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let evalAfterSetOne = splitClient.getTreatment(splitName)

        _ = splitClient.setAttributes([Attr.numValueA: attrValues[Attr.numValueA]!,
                              Attr.strValue: attrValues[Attr.strValue]!])

        let evalAfterSetMany = splitClient.getTreatment(splitName)

        _ = splitClient.removeAttribute(name: Attr.strValue)

        let evalAfterRemoveOne = splitClient.getTreatment(splitName)

        _ = splitClient.clearAttributes()

        let evalAfterClear = splitClient.getTreatment(splitName)

        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual("on_str_no", evalAfterSetOne)
        XCTAssertEqual("on_str_yes", evalAfterSetMany)
        XCTAssertEqual("on_num_20", evalAfterRemoveOne)
        XCTAssertEqual("on", evalAfterClear)

        splitClient.destroy()
    }

    private func getChanges() -> Data {
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                return TestDispatcherResponse(code: 500, data: self.getChanges())

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            }
            return self.streamingBinding!
        }
    }

    private func buildSplitEntity() -> Split {
        let content = FileHelper.readDataFromFile(sourceClass: IntegrationHelper(), name: "attributes_test_split", type: "json")!
        return try! Json.encodeFrom(json: content, to: Split.self)
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        //splitConfig.isDebugModeEnabled = true
        return splitConfig
    }
}


