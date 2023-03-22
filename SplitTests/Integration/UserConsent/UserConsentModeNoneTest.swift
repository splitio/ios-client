//
//  UserConsentModeNoneTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class UserConsentModeNoneTest: XCTestCase {

    var keysExp: XCTestExpectation!
    var countExp: XCTestExpectation!

    var countsDao: ImpressionsCountDao!
    var keysDao: UniqueKeyDao!
    var splitChange = IntegrationHelper.loadSplitChangeFileJson(name: "splitchanges_1", sourceClass: IntegrationHelper())
    let trafficType = "account"
    var httpClient: HttpClient!
    var notificationHelper: NotificationHelperStub!

    var countPosted = false
    var keysPosted = false

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        countPosted = false
        keysPosted = false
    }

    func testUserConsentGranted() {
        let factory = createFactory(userConsent: .granted)
        let readyExp = XCTestExpectation()
        keysExp = XCTestExpectation()
        countExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        evaluate(client: client)

        // Impressions count and keys are saved when app goes to bg and previous
        // and on flush() call
        notificationHelper.simulateApplicationDidEnterBackground()
        notificationHelper.simulateApplicationDidBecomeActive()
        wait(for: [keysExp, countExp], timeout: 10.0)

        XCTAssertTrue(keysPosted)
        XCTAssertTrue(countPosted)
    }

    func testUserConsentDeclined() {
        let factory = createFactory(userConsent: .declined)
        let readyExp = XCTestExpectation()
        keysExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        evaluate(client: client)

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // load data from db
        let keys = keysDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)
        let eve = countsDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)

        XCTAssertFalse(keysPosted)
        XCTAssertFalse(countPosted)
        XCTAssertEqual(0, keys.count)
        XCTAssertEqual(0, eve.count)
    }

    func testUserConsentUnknownThenGranted() {
        let factory = createFactory(userConsent: .unknown)
        let readyExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        evaluate(client: client)

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let keysPostedBeforeEnable = keysPosted
        let countPostedBeforeEnable = countPosted

        keysPosted = false
        countPosted = false

        keysExp = XCTestExpectation()
        countExp = XCTestExpectation()
        factory.setUserConsent(enabled: true)
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        wait(for: [keysExp, countExp], timeout: 10.0)
        let keysPostedAfterEnable = keysPosted
        let countPostedAfterEnable = countPosted

        XCTAssertFalse(keysPostedBeforeEnable)
        XCTAssertFalse(countPostedBeforeEnable)

        // This means that there was tracked data in memory
        // and was persisted and sent after enabling user consent
        // Not measu
        XCTAssertTrue(keysPostedAfterEnable)
        XCTAssertTrue(countPostedAfterEnable)
    }

    func testUserConsentUnknownThenDeclined() {
        let factory = createFactory(userConsent: .unknown)
        let readyExp = XCTestExpectation()
        keysExp = XCTestExpectation()
        countExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        evaluate(client: client)

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let keysPostedBeforeEnable = keysPosted
        let countPostedBeforeEnable = countPosted

        keysPosted = false
        countPosted = false

        factory.setUserConsent(enabled: false)
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let keysPostedAfterDecline = keysPosted
        let countPostedAfterDecline = countPosted

        factory.setUserConsent(enabled: false)
        ThreadUtils.delay(seconds: 2)

        let imp = keysDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)
        let eve = countsDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)

        XCTAssertFalse(keysPostedBeforeEnable)
        XCTAssertFalse(countPostedBeforeEnable)

        // This means that there was tracked data in memory
        // and was not persisted nor sent after declining user consent
        // Not measu
        XCTAssertFalse(keysPostedAfterDecline)
        XCTAssertFalse(countPostedAfterDecline)

        XCTAssertEqual(0, imp.count)
        XCTAssertEqual(0, eve.count)
    }

    private func evaluate(client: SplitClient) {
        let splits = [
            "FACUNDO_TEST", "FACUNDO_TEST", "testing", "testing",
            "testing222", "testing222", "a_new_split_2", "a_new_split_2",
            "test_string_without_attr", "test_string_without_attr"
        ]

        for split in splits {
            let _ = client.getTreatment(split)
        }
    }

    func createFactory(userConsent: UserConsent) -> SplitFactory {
        let db = TestingHelper.createTestDatabase(name: "UserConsentTest")
        keysDao = db.uniqueKeyDao
        countsDao = db.impressionsCountDao
        notificationHelper = NotificationHelperStub()

        // If User consent is granted, it would be data in storage and
        // Impressions posted
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.impressionRefreshRate = 3
        splitConfig.trafficType = trafficType
        splitConfig.impressionsCountsRefreshRate = 3
        splitConfig.uniqueKeysRefreshRate = 3
        splitConfig.logLevel = .verbose
        splitConfig.impressionsMode = "NONE"
        splitConfig.userConsent = userConsent

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(db)
        _ = builder.setHttpClient(httpClient)
        _ = builder.setNotificationHelper(notificationHelper)
        return builder.setApiKey(IntegrationHelper.dummyApiKey)
            .setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
            .setConfig(splitConfig).build()!

    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            return TestStreamResponseBinding.createFor(request: request, code: 200)
        }
    }

    var changeHit = 0
    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in

            switch request.url.absoluteString {
            case let(urlString) where urlString.contains("splitChanges"):
                if self.changeHit == 0 {
                    self.changeHit+=1
                    return TestDispatcherResponse(code: 200, data: Data(self.splitChange!.utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 999999999, till: 999999999).utf8))

            case let(urlString) where urlString.contains("mySegments"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))

            case let(urlString) where urlString.contains("auth"):
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))

            case let(urlString) where urlString.contains("keys/cs"):
                self.keysPosted = true
                if let exp = self.keysExp {
                    exp.fulfill()
                }
                return TestDispatcherResponse(code: 200)

            case let(urlString) where urlString.contains("testImpressions/count"):
                self.countPosted = true
                if let exp = self.countExp {
                    exp.fulfill()
                }
                return TestDispatcherResponse(code: 200)

            default:
                return TestDispatcherResponse(code: 200)
            }
        }
    }
}

