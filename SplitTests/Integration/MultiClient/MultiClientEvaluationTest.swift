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
    let defaultKey = "key_default"
    let key1 = "key_1"
    let key2 = "key_2"
    let key3 = "key_3"
    let key4 = "key_4"

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

    func testOne() {
        var clients = [String: SplitClient]()
        var readyExps = [String: XCTestExpectation]()
        var cache = [String: Bool]()

        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()

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
        clients[key2] = factory.client(matchingKey: key2)
        clients[key3] = factory.client(matchingKey: key3, bucketingKey: "buckKey")
        clients[key4] = factory.client(matchingKey: key4)

        for (key, _) in clients {
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")
            clients[key]?.on(event: SplitEvent.sdkReadyFromCache) {
                cache[key] = true
                print("Ready from cache")
            }

            clients[key]?.on(event: SplitEvent.sdkReady) {
                readyExps[key]?.fulfill()
                print("Ready")
            }
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        var results = [String: String]()
        for (key, client) in clients {
            results[key] = client.getTreatment(splitName)
        }

        let expectedResults = [defaultKey: "on_key_default", key1: "on_key_1",
                                     key2: "on_key_2", key3: "on_key_3", key4: "default_t"]
        for (key, _) in clients {
            XCTAssertEqual(expectedResults[key] ?? "", results[key] ?? "")
        }

        for client in clients.values {
            client.destroy()
        }
    }

    private func getChanges() -> Data {
        let changeNumber = 5000
        var content = FileHelper.readDataFromFile(sourceClass: IntegrationHelper(), name: "multi_client_test", type: "json")!
        content = content.replacingOccurrences(of: "<FIELD_SINCE>", with: "\(changeNumber)")
        content = content.replacingOccurrences(of: "<FIELD_TILL>", with: "\(changeNumber)")
        return Data(content.utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {

        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                return TestDispatcherResponse(code: 200, data: self.getChanges())

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


