//
//  MultiClientStreamingResetTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class MultiClientStreamingResetTest: XCTestCase {

    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    let defaultKey = "key_default"
    let trafficType = "client"

    let key1 = "key_1"
    let key2 = "key_2"
    let key3 = "key_3"
    let key4 = "key_4"

    var authHitCount = 0
    var sseHitCount = 0

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.global())

    var cachedSplit: Split!
    var clients = [Key: SplitClient]()
    var readyExps = [String: XCTestExpectation]()
    var streamExps = [String: XCTestExpectation]()
    var factory: SplitFactory!

    var expAuth: XCTestExpectation?
    var expSse: XCTestExpectation?

    override func setUp() {
        authHitCount = 0
        sseHitCount = 0
    }

    func testNoStreamingDelay() {
        setupFactory()
        execTest(delay: false)
    }

    func testWithStreamingDelay() {
        setupFactory(streamDelay: 3)
        execTest(delay: true)
    }

    private func execTest(delay: Bool = false) {

        var results = [String: String]()
        let defaultClient = factory.client
        clients[Key(matchingKey: defaultKey)] = defaultClient
        let expReady = XCTestExpectation(description: "Ready \(defaultKey)")
        expAuth = XCTestExpectation(description: "Auth \(defaultKey)")
        defaultClient.on(event: SplitEvent.sdkReady) {
            expReady.fulfill()
            results[self.defaultKey] = defaultClient.getTreatment(self.splitName)
        }

        var exps = [expReady, expAuth!]
        if !delay {
            expSse = (XCTestExpectation(description: "Streaming \(defaultKey)"))
            exps.append(expSse!)
        }
        wait(for: exps, timeout: 5)
        let keyCount = 3
        for i in 1...3 {
            let key = Key(matchingKey: "key_\(i)")
            let client = factory.client(key: key)
            self.clients[key] = client
            let expReady = XCTestExpectation(description: "Ready \(key.matchingKey)")
            self.expAuth = XCTestExpectation(description: "Auth \(key.matchingKey)")

            var exps = [expReady, expAuth!]
            if !delay || i == keyCount {
                self.expSse = (XCTestExpectation(description: "Streaming \(defaultKey)"))
                exps.append(expSse!)
            }

            client.on(event: SplitEvent.sdkReady) {
                expReady.fulfill()
                results[key.matchingKey] = client.getTreatment(self.splitName)
            }
            wait(for: exps, timeout: 10)
        }

        // defaultKey is whitelisted.
        // key1 to key3 has its own whitelist
        // key4 evaluates to default treatment
        let expectedResults = [defaultKey: "on_key_default", key1: "on_key_1",
                                     key2: "on_key_2", key3: "on_key_3", key4: "default_t"]
        doInAllClients { key, _ in
            XCTAssertEqual(expectedResults[key.matchingKey] ?? "", results[key.matchingKey] ?? "")
        }
        XCTAssertEqual(clients.count, authHitCount)

        if !delay {
            XCTAssertEqual(clients.count, sseHitCount)
        } else {
            XCTAssertEqual(1, sseHitCount)
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

    private func buildTestDispatcher(streamingDelay: Int = 0) -> HttpClientTestDispatcher {

        return { request in
            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                return TestDispatcherResponse(code: 200, data: self.getChanges())

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                self.authHitCount+=1
                self.expAuth?.fulfill()
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse(delay: streamingDelay).utf8))

            default:
                return TestDispatcherResponse(code: 200)
            }
        }
    }

    private func doInAllClients(action: (Key, SplitClient) -> Void) {
        for (key, client) in clients {
            action(key, client)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.sseHitCount+=1
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.expSse?.fulfill()
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

    private func setupFactory(database: SplitDatabase? = nil,streamDelay: Int = 0) {
        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = database ?? TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(streamingDelay: streamDelay),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.trafficType = trafficType

        let key: Key = Key(matchingKey: defaultKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!
    }

    private func event(from data: Data?) -> [EventDTO]? {
        guard let data = data else { return nil }
        do {
            return try Json.dynamicEncodeFrom(json: data.stringRepresentation, to: [EventDTO].self)
        } catch {
            print(error)
        }
        return nil
    }

    private func impressions(from data: Data?) -> [KeyImpression]? {
        guard let data = data else { return nil }
        do {
            let tests =  try Json.encodeFrom(json: data.stringRepresentation, to: [ImpressionsTest].self)
            return tests.flatMap { $0.keyImpressions }
        } catch {
            print(error)
        }
        return nil
    }
}


