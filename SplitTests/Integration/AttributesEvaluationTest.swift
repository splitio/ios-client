//
//  AttributesEvaluationTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class AttributesEvaluationTest: XCTestCase {

    let splitName = "workm"
    var streamingBinding: TestStreamResponseBinding?
    var userKey = IntegrationHelper.dummyUserKey

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

    func testPersistentEvalNoAttributesSeveralOperations() {

        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = true

        let cacheReadyExp = XCTestExpectation()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)

        let evalAfterInit = client.getTreatment(splitName)

        _ = client.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let evalAfterSetOne = client.getTreatment(splitName)

        _ = client.setAttributes([Attr.numValueA: attrValues[Attr.numValueA]!,
                              Attr.strValue: attrValues[Attr.strValue]!])

        let evalAfterSetMany = client.getTreatment(splitName)

        _ = client.removeAttribute(name: Attr.strValue)

        let evalAfterRemoveOne = client.getTreatment(splitName)

        _ = client.clearAttributes()

        let evalAfterClear = client.getTreatment(splitName)

        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual("on_str_no", evalAfterSetOne)
        XCTAssertEqual("on_str_yes", evalAfterSetMany)
        XCTAssertEqual("on_num_20", evalAfterRemoveOne)
        XCTAssertEqual("on", evalAfterClear)

        client.destroy()
    }

    func testAttributesPersistentedCorrectly() {

        // When splits and connection available, ready from cache and Ready should be fired
        let attr: [String: Any] = [Attr.numValue: attrValues[Attr.numValue]!,
                                   Attr.strValue: attrValues[Attr.strValue]!]
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100)
        splitDatabase.attributesDao.update(userKey: userKey, attributes: attr)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = true

        let cacheReadyExp = XCTestExpectation()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)

        let initAttributes = client.getAttributes()

        let evalAfterInit = client.getTreatment(splitName)

        _ = client.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let dbSetOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = client.removeAttribute(name: Attr.strValue)

        let dbRemoveOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = client.setAttributes([Attr.numValueA: attrValues[Attr.numValueA]!,
                              Attr.strValue: attrValues[Attr.strValue]!])

        let dbSetManyAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = client.clearAttributes()

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

        client.destroy()
    }

    func testPersistenceDisabled() {

        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100)
        let attr: [String: Any] = [Attr.numValue: attrValues[Attr.numValue]!,
                                   Attr.strValue: attrValues[Attr.strValue]!]
        splitDatabase.attributesDao.update(userKey: userKey, attributes: attr)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = false

        let cacheReadyExp = XCTestExpectation()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)

        let initAttributes = client.getAttributes()

        let evalAfterInit = client.getTreatment(splitName)

        _ = client.setAttribute(name: Attr.strValueA, value: attrValues[Attr.strValueA]!)

        let dbSetOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = client.removeAttribute(name: Attr.strValueA)

        let dbRemoveOneAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        _ = client.setAttributes([Attr.numValue: attrValues[Attr.numValue]!,
                              Attr.strValue: attrValues[Attr.strValue]!,
                              Attr.numValueA: attrValues[Attr.numValueA]!])

        let dbSetManyAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)

        let inMemoryAttributes = client.getAttributes()

        _ = client.clearAttributes()

        let dbClearedAttributes = splitDatabase.attributesDao.getBy(userKey: userKey)


        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual(0, initAttributes?.count ?? 10)
        XCTAssertEqual(2, dbSetOneAttributes?.count ?? 0)
        XCTAssertEqual(2, dbRemoveOneAttributes?.count ?? 0)
        XCTAssertEqual(2, dbSetManyAttributes?.count ?? 0)
        XCTAssertEqual(2, dbClearedAttributes?.count ?? 0)
        XCTAssertEqual(3, inMemoryAttributes?.count ?? 0)

        client.destroy()
    }

    func testEvaluationPrecedence() {

        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = TestingHelper.createTestDatabase(name: "attr_test")
        splitDatabase.splitDao.insertOrUpdate(split: cachedSplit)
        splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: 100)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.persistentAttributesEnabled = false

        let cacheReadyExp = XCTestExpectation()

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        let factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        client.on(event: SplitEvent.sdkReadyFromCache) {
            cacheReadyExp.fulfill()
        }

        wait(for: [cacheReadyExp], timeout: 10)

        let evalAfterInit = client.getTreatment(splitName)

        _ = client.setAttributes([Attr.numValueA: attrValues[Attr.numValueA]!,
                              Attr.strValue: "no_match_value"])

        let evalAfterOverwrite = client.getTreatment(splitName,
                                                     attributes: [ Attr.strValue: attrValues[Attr.strValue]!])

        let evalPrecedence = client.getTreatment(splitName,
                                                     attributes: [ Attr.numValue: attrValues[Attr.numValue]!])

        XCTAssertEqual("on", evalAfterInit)
        XCTAssertEqual("on_str_yes", evalAfterOverwrite)
        XCTAssertEqual("on_num_10", evalPrecedence)

        client.destroy()
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

