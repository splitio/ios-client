//
//  AttributesEvaluationTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class AttributesEvaluationTest: XCTestCase {
    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    var userKey = IntegrationHelper.dummyUserKey

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.test)

    var splitClient: SplitClient!

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

    override func setUp() {
        cachedSplit = buildSplitEntity()
    }

    func testPersistentEvalNoAttributesSeveralOperations() {
        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = true

        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        splitClient = factory.client

        splitClient.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            print("Ready from cache")
        }

        wait(for: [cacheReadyExp], timeout: 5)

        let evalAfterInit = splitClient.getTreatment(splitName)

        _ = splitClient.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let evalAfterSetOne = splitClient.getTreatment(splitName)

        _ = splitClient.setAttributes([
            Attr.numValueA: attrValues[Attr.numValueA]!,
            Attr.strValue: attrValues[Attr.strValue]!,
        ])

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

        let semaphore = DispatchSemaphore(value: 0)
        splitClient.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testAttributesPersistentedCorrectly() {
        // When splits and connection available, ready from cache and Ready should be fired
        let attr: [String: Any] = [
            Attr.numValue: attrValues[Attr.numValue]!,
            Attr.strValue: attrValues[Attr.strValue]!,
        ]
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: cachedSplit)
        splitDatabase.attributesDao.syncUpdate(userKey: userKey, attributes: attr)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = true

        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        splitClient = factory.client

        splitClient.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            print("Ready from cache")
        }

        wait(for: [cacheReadyExp], timeout: 5)

        let initAttributes = splitClient.getAttributes()

        let evalAfterInit = splitClient.getTreatment(splitName)

        _ = splitClient.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let dbSetOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = splitClient.removeAttribute(name: Attr.strValue)

        let dbRemoveOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = splitClient.setAttributes([
            Attr.numValueA: attrValues[Attr.numValueA]!,
            Attr.strValue: attrValues[Attr.strValue]!,
        ])

        let dbSetManyAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = splitClient.clearAttributes()

        let dbClearedAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        XCTAssertEqual(2, initAttributes?.count ?? 0)
        XCTAssertEqual(attrValues[Attr.numValue] as? Int, initAttributes?[Attr.numValue] as? Int)
        XCTAssertEqual(attrValues[Attr.strValue] as? String, initAttributes?[Attr.strValue] as? String)
        XCTAssertEqual("on_num_10", evalAfterInit)

        XCTAssertEqual(3, dbSetOneAttributes?.count ?? 0)
        XCTAssertEqual(attrValues[Attr.numValue] as? Int, dbSetOneAttributes?[Attr.numValue] as? Int)
        XCTAssertEqual(attrValues[Attr.strValue] as? String, dbSetOneAttributes?[Attr.strValue] as? String)
        XCTAssertEqual(attrValues[Attr.strValueA] as? String, dbSetOneAttributes?[Attr.strValueA] as? String)

        XCTAssertEqual(2, dbRemoveOneAttributes?.count ?? 0)
        XCTAssertEqual(attrValues[Attr.numValue] as? Int, dbRemoveOneAttributes?[Attr.numValue] as? Int)
        XCTAssertEqual(attrValues[Attr.strValueA] as? String, dbRemoveOneAttributes?[Attr.strValueA] as? String)

        XCTAssertEqual(4, dbSetManyAttributes?.count ?? 0)
        XCTAssertEqual(attrValues[Attr.numValue] as? Int, dbSetManyAttributes?[Attr.numValue] as? Int)
        XCTAssertEqual(attrValues[Attr.numValueA] as? Int, dbSetManyAttributes?[Attr.numValueA] as? Int)
        XCTAssertEqual(attrValues[Attr.strValue] as? String, dbSetManyAttributes?[Attr.strValue] as? String)
        XCTAssertEqual(attrValues[Attr.strValueA] as? String, dbSetManyAttributes?[Attr.strValueA] as? String)

        XCTAssertNil(dbClearedAttributes?.count)

        let semaphore = DispatchSemaphore(value: 0)
        splitClient.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testPersistenceDisabled() {
        // When feature flags and connection available, ready from cache and Ready should be fired
        let attr: [String: Any] = [
            Attr.numValue: attrValues[Attr.numValue]!,
            Attr.strValue: attrValues[Attr.strValue]!,
        ]
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: cachedSplit)
        splitDatabase.attributesDao.syncUpdate(userKey: userKey, attributes: attr)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = false

        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        splitClient = factory.client

        splitClient.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            print("Ready from cache")
        }

        wait(for: [cacheReadyExp], timeout: 5)

        let initAttributes = splitClient.getAttributes()

        let evalAfterInit = splitClient.getTreatment(splitName)

        _ = splitClient.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let dbSetOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = splitClient.removeAttribute(name: Attr.strValueA)

        let dbRemoveOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = splitClient.setAttributes([
            Attr.numValue: attrValues[Attr.numValue]!,
            Attr.strValue: attrValues[Attr.strValue]!,
            Attr.numValueA: attrValues[Attr.numValueA]!,
        ])

        let dbSetManyAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        let inMemoryAttributes = splitClient.getAttributes()

        _ = splitClient.clearAttributes()

        let dbClearedAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual(0, initAttributes?.count ?? 10)
        XCTAssertEqual(2, dbSetOneAttributes?.count ?? 0)
        XCTAssertEqual(2, dbRemoveOneAttributes?.count ?? 0)
        XCTAssertEqual(2, dbSetManyAttributes?.count ?? 0)
        XCTAssertEqual(2, dbClearedAttributes?.count ?? 0)
        XCTAssertEqual(3, inMemoryAttributes?.count ?? 0)

        let semaphore = DispatchSemaphore(value: 0)
        splitClient.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    func testEvaluationPrecedence() {
        // When feature flags and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test", queue: dbqueue)
        splitDatabase.splitDao.syncInsertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .flagsSpec, stringValue: Spec.flagsSpec)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = false

        let cacheReadyExp = XCTestExpectation()

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        splitClient = factory.client

        splitClient.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
            print("Ready from cache")
        }

        wait(for: [cacheReadyExp], timeout: 5)

        let evalAfterInit = splitClient.getTreatment(splitName)

        _ = splitClient.setAttributes([
            Attr.numValueA: attrValues[Attr.numValueA]!,
            Attr.strValue: "no_match_value",
        ])

        let evalAfterOverwrite = splitClient.getTreatment(
            splitName,
            attributes: [Attr.strValue: attrValues[Attr.strValue]!])

        let evalPrecedence = splitClient.getTreatment(
            splitName,
            attributes: [Attr.numValue: attrValues[Attr.numValue]!])

        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual("on_str_yes", evalAfterOverwrite)
        XCTAssertEqual("on_num_10", evalPrecedence)

        let semaphore = DispatchSemaphore(value: 0)
        splitClient.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func getChanges() -> Data {
        return Data(IntegrationHelper.emptySplitChanges(since: 999999, till: 999999).utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            switch request.url.absoluteString {
            case let urlString where urlString.contains("splitChanges"):
                return TestDispatcherResponse(code: 500, data: self.getChanges())

            case let urlString where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let urlString where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            default:
                return TestDispatcherResponse(code: 500)
            }
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {}
            return self.streamingBinding!
        }
    }

    private func buildSplitEntity() -> Split {
        let content = FileHelper.readDataFromFile(
            sourceClass: IntegrationHelper(),
            name: "attributes_test_split",
            type: "json")!
        return try! Json.decodeFrom(json: content, to: Split.self)
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        splitConfig.logLevel = .verbose
        return splitConfig
    }
}
