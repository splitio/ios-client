//
//  MultiClientEvaluation.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class MultiClientEvaluationTest: XCTestCase {
    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    let defaultKey = "key_default"
    let trafficType = "client"
    let key1 = "key_1"
    let key2 = "key_2"
    let key3 = "key_3"
    let key4 = "key_4"
    let key5 = "key_5"
    let key6 = "key_6"

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.test)

    enum Attr {
        static let numValue = "num_value"
        static let strValue = "str_value"
        static let numValueA = "num_value_a"
        static let strValueA = "str_value_a"
    }

    let attrValues: [String: Any] = [
        Attr.numValue: 10,
        Attr.strValue: "yes",
        Attr.numValueA: 20,
        Attr.strValueA: "no",
    ]

    var cachedSplit: Split!
    var clients = [String: SplitClient]()
    var readyExps = [String: XCTestExpectation]()
    var factory: SplitFactory!

    override func setUp() {
        IntegrationCoreDataHelper.observeChanges()
        readyExps = [String: XCTestExpectation]()
        setupFactory()
    }

    override func tearDown() {
        IntegrationCoreDataHelper.stopObservingChanges()
    }

    func testEvaluation() {
        clients[defaultKey] = factory.client

        // Using all new API methods
        clients[key1] = factory.client(key: Key(matchingKey: key1))
        clients[key2] = factory.client(matchingKey: key2)
        clients[key3] = factory.client(matchingKey: key3, bucketingKey: "buckKey")
        clients[key4] = factory.client(matchingKey: key4)

        doInAllClients { key, client in
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")

            print("Handler for: \(key)")
            clients[key]?.on(event: SplitEvent.sdkReady) {
                self.readyExps[key]?.fulfill()
            }
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        var results = [String: String]()
        doInAllClients { key, client in
            results[key] = client.getTreatment(splitName)
        }

        // defaultKey is whitelisted.
        // key1 to key3 has its own whitelist
        // key4 evaluates to default treatment
        let expectedResults = [
            defaultKey: "on_key_default",
            key1: "on_key_1",
            key2: "on_key_2",
            key3: "on_key_3",
            key4: "default_t",
        ]
        doInAllClients { key, _ in
            XCTAssertEqual(expectedResults[key] ?? "", results[key] ?? "")
        }

        for client in clients.values {
            client.destroy()
        }
    }

    func testEvaluationFromCache() {
        let dbExp = IntegrationCoreDataHelper.getDbExp(
            count: 1,
            entity: .generalInfo,
            operation: CrudKey.insert)
        var cache = [String: Bool]()
        let changes = try! Json.decodeFrom(json: getChanges().stringRepresentation, to: TargetingRulesChange.self)
        let db = TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)
        db.splitDao.syncInsertOrUpdate(split: changes.featureFlags.splits[0])
        db.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        setupFactory(database: db)

        wait(for: [dbExp], timeout: 10.0)

        clients[defaultKey] = factory.client

        for i in 1 ..< 4 {
            clients["key_\(i)"] = factory.client(key: Key(matchingKey: "key_\(i)"))
        }

        doInAllClients { key, client in
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")
            clients[key]?.on(event: SplitEvent.sdkReadyFromCache) {
                self.readyExps[key]?.fulfill()
                cache[key] = true
            }
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        var results = [String: String]()
        doInAllClients { key, client in
            results[key] = client.getTreatment(splitName)
        }

        // defaultKey is whitelisted.
        // key1 to key3 has its own whitelist
        // key4 evaluates to default treatment
        let expectedResults = [
            defaultKey: "on_key_default",
            key1: "on_key_1",
            key2: "on_key_2",
            key3: "on_key_3",
            key4: "default_t",
        ]
        doInAllClients { key, _ in
            XCTAssertEqual(expectedResults[key] ?? "", results[key] ?? "")
            XCTAssertTrue(cache[key] ?? false)
        }

        for client in clients.values {
            client.destroy()
        }
    }

    func testEvaluationWithAttributes() {
        clients[defaultKey] = factory.client

        for i in 4 ..< 6 {
            let key = "key_\(i)"
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")
            let client = factory.client(key: Key(matchingKey: key))
            client.on(event: SplitEvent.sdkReady) {
                self.readyExps[key]?.fulfill()
            }
            clients[key] = client
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        _ = clients[key5]?.setAttribute(name: "str_value_a", value: "yes")

        var results = [String: String]()
        doInAllClients { key, client in
            results[key] = client.getTreatment(splitName)
        }
        results[key6] = clients[key6]?.getTreatment(splitName, attributes: ["str_value_a": "yes"])

        // defaultKey is whitelisted.
        // key4 evaluates to default treatment
        // key5 evaluates using attributes on get treatment
        // key6 has stored attributes
        let expectedResults = [
            defaultKey: "on_key_default",
            key4: "default_t",
            key5: "str_yes",
            key6: "str_yes",
        ]
        doInAllClients { key, _ in
            XCTAssertEqual(expectedResults[key] ?? "", results[key] ?? "")
        }

        for client in clients.values {
            client.destroy()
        }
    }

    var eventsSent = [String: EventDTO]()
    var eventsExp = XCTestExpectation(description: "events exp")
    func testTrack() {
        clients[defaultKey] = factory.client

        for i in 1 ..< 4 {
            clients["key_\(i)"] = factory.client(key: Key(matchingKey: "key_\(i)"))
        }

        doInAllClients { key, client in
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")

            clients[key]?.on(event: SplitEvent.sdkReady) {
                self.readyExps[key]?.fulfill()
            }
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        var trackResult = [String: Bool]()
        doInAllClients { key, client in
            trackResult[key] = client.track(eventType: "ev_\(key)")
        }
        clients[defaultKey]?.flush()
        wait(for: [eventsExp], timeout: 5)

        doInAllClients { key, _ in
            let event = eventsSent[key]
            XCTAssertTrue(trackResult[key] ?? false)
            XCTAssertNotNil(event)
            XCTAssertEqual(key, event?.key)
            XCTAssertEqual(trafficType, event?.trafficTypeName)
        }

        doInAllClients { _, client in
            client.destroy()
        }
    }

    var impressionsSent = [String: KeyImpression]()
    var impressionsExp = XCTestExpectation(description: "impressions exp")
    func testImpressions() {
        clients[defaultKey] = factory.client

        for i in 1 ..< 4 {
            clients["key_\(i)"] = factory.client(key: Key(matchingKey: "key_\(i)"))
        }

        doInAllClients { key, client in
            readyExps[key] = XCTestExpectation(description: "Ready \(key)")

            clients[key]?.on(event: SplitEvent.sdkReady) {
                self.readyExps[key]?.fulfill()
            }
        }

        wait(for: readyExps.values.map { $0 }, timeout: 5)

        doInAllClients { key, client in
            _ = client.getTreatment(splitName)
        }
        clients[defaultKey]?.flush()
        wait(for: [impressionsExp], timeout: 5)

        doInAllClients { key, _ in
            let impression = impressionsSent[key]
            XCTAssertNotNil(impression)
            XCTAssertEqual("on_\(key)", impression?.treatment ?? "")
            XCTAssertEqual(key, impression?.keyName)
        }

        doInAllClients { _, client in
            client.destroy()
        }
    }

    private func getChanges() -> Data {
        let changeNumber = 5000
        var content = FileHelper.readDataFromFile(
            sourceClass: IntegrationHelper(),
            name: "multi_client_test",
            type: "json")!
        content = content.replacingOccurrences(of: "<FIELD_SINCE>", with: "\(changeNumber)")
        content = content.replacingOccurrences(of: "<FIELD_TILL>", with: "\(changeNumber)")
        return Data(content.utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(code: 200, data: self.getChanges())
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            if request.isEventsEndpoint() {
                if let events = self.event(from: request.body) {
                    for event in events {
                        self.eventsSent[event.key ?? "unknown"] = event
                    }
                }
                self.eventsExp.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            if request.isImpressionsEndpoint() {
                if let impressions = self.impressions(from: request.body) {
                    for impression in impressions {
                        self.impressionsSent[impression.keyName] = impression
                    }
                }
                self.impressionsExp.fulfill()
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    private func doInAllClients(action: (String, SplitClient) -> Void) {
        for (key, client) in clients {
            action(key, client)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {}
            return self.streamingBinding!
        }
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = TestingHelper.testLogLevel
        return splitConfig
    }

    private func setupFactory(database: SplitDatabase? = nil) {
        // When feature flags and connection available, ready from cache and Ready should be fired
        let splitDatabase = database ?? TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.trafficType = trafficType

        let key = Key(matchingKey: defaultKey)
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
            return try Json.dynamicDecodeFrom(json: data.stringRepresentation, to: [EventDTO].self)
        } catch {
            print(error)
        }
        return nil
    }

    private func impressions(from data: Data?) -> [KeyImpression]? {
        guard let data = data else { return nil }
        do {
            let tests = try Json.decodeFrom(json: data.stringRepresentation, to: [ImpressionsTest].self)
            return tests.flatMap { $0.keyImpressions }
        } catch {
            print(error)
        }
        return nil
    }
}
