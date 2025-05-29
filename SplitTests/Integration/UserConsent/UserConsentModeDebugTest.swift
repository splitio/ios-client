//
//  UserConsentModeDebugTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class UserConsentModeDebugTest: XCTestCase {
    var impExp: XCTestExpectation!
    var eveExp: XCTestExpectation!
    var impDao: ImpressionDao!
    var eveDao: EventDao!
    var splitChange = IntegrationHelper.loadSplitChangeFileJson(
        name: "splitchanges_1",
        sourceClass: IntegrationHelper())
    let trafficType = "account"
    var httpClient: HttpClient!

    var impPosted = false
    var evePosted = false

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        evePosted = false
        impPosted = false
    }

    func testUserConsentGranted() {
        let factory = createFactory(userConsent: .granted)
        let readyExp = XCTestExpectation()
        impExp = XCTestExpectation()
        eveExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        for i in 1 ..< 20 {
            let _ = client.getTreatment("FACUNDO_TEST")
            let _ = client.track(eventType: "ev", value: Double(i))
        }

        wait(for: [impExp, eveExp], timeout: 10.0)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()

        XCTAssertTrue(impPosted)
        XCTAssertTrue(evePosted)
    }

    func testUserConsentDeclined() {
        let factory = createFactory(userConsent: .declined)
        let readyExp = XCTestExpectation()
        impExp = XCTestExpectation()
        eveExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        for i in 1 ..< 20 {
            let _ = client.getTreatment("FACUNDO_TEST")
            let _ = client.track(eventType: "ev", value: Double(i))
        }

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // load data from db
        let imp = impDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)
        let eve = eveDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()

        XCTAssertFalse(impPosted)
        XCTAssertFalse(evePosted)
        XCTAssertEqual(0, imp.count)
        XCTAssertEqual(0, eve.count)
    }

    func testUserConsentUnknownThenGranted() {
        let factory = createFactory(userConsent: .unknown)
        let readyExp = XCTestExpectation()
        impExp = XCTestExpectation()
        eveExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        for i in 0 ..< 20 {
            let _ = client.getTreatment("FACUNDO_TEST")
            let _ = client.track(eventType: "ev", value: Double(i))
        }

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let impPostedBeforeEnable = impPosted
        let evePostedBeforeEnable = evePosted

        impPosted = false
        evePosted = false

        factory.setUserConsent(enabled: true)
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        wait(for: [impExp, eveExp], timeout: 10.0)
        let impPostedAfterEnable = impPosted
        let evePostedAfterEnable = evePosted

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()

        XCTAssertFalse(impPostedBeforeEnable)
        XCTAssertFalse(evePostedBeforeEnable)

        // This means that there was tracked data in memory
        // and was persisted and sent after enabling user consent
        // Not measu
        XCTAssertTrue(impPostedAfterEnable)
        XCTAssertTrue(evePostedAfterEnable)
    }

    func testUserConsentUnknownThenDeclined() {
        let factory = createFactory(userConsent: .unknown)
        let readyExp = XCTestExpectation()
        impExp = XCTestExpectation()
        eveExp = XCTestExpectation()

        let client = factory.client
        client.on(event: .sdkReady) {
            readyExp.fulfill()
        }

        wait(for: [readyExp], timeout: 5.0)

        for i in 0 ..< 20 {
            let _ = client.getTreatment("FACUNDO_TEST")
            let _ = client.track(eventType: "ev", value: Double(i))
        }

        // Wait for data to be stored
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let impPostedBeforeEnable = impPosted
        let evePostedBeforeEnable = evePosted

        impPosted = false
        evePosted = false

        factory.setUserConsent(enabled: false)
        ThreadUtils.delay(seconds: 2)

        // Flush and wait
        client.flush()
        ThreadUtils.delay(seconds: 2)
        let impPostedAfterDecline = impPosted
        let evePostedAfterDecline = evePosted

        factory.setUserConsent(enabled: false)
        ThreadUtils.delay(seconds: 2)

        let imp = impDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)
        let eve = eveDao.getBy(createdAt: -1, status: StorageRecordStatus.active, maxRows: 100)

        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()

        XCTAssertFalse(impPostedBeforeEnable)
        XCTAssertFalse(evePostedBeforeEnable)

        // This means that there was tracked data in memory
        // and was not persisted nor sent after declining user consent
        // Not measu
        XCTAssertFalse(impPostedAfterDecline)
        XCTAssertFalse(evePostedAfterDecline)

        XCTAssertEqual(0, imp.count)
        XCTAssertEqual(0, eve.count)
    }

    func createFactory(userConsent: UserConsent) -> SplitFactory {
        let db = TestingHelper.createTestDatabase(name: "UserConsentTest")
        impDao = db.impressionDao
        eveDao = db.eventDao

        // If User consent is granted, it would be data in storage and
        // Impressions posted
        let splitConfig = SplitClientConfig()
        splitConfig.impressionRefreshRate = 3
        splitConfig.trafficType = trafficType
        splitConfig.eventsPushRate = 3
        splitConfig.eventsFirstPushWindow = 0
        splitConfig.logLevel = TestingHelper.testLogLevel
        splitConfig.impressionsMode = "DEBUG"
        splitConfig.userConsent = userConsent

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(db)
        _ = builder.setHttpClient(httpClient)
        return builder.setApiKey(IntegrationHelper.dummyApiKey)
            .setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
            .setConfig(splitConfig).build()!
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            TestStreamResponseBinding.createFor(request: request, code: 200)
        }
    }

    var changeHit = 0
    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in

            if request.isSplitEndpoint() {
                if self.changeHit == 0 {
                    self.changeHit += 1
                    return TestDispatcherResponse(code: 200, data: Data(self.splitChange!.utf8))
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 999999999, till: 999999999).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.impPosted = true
                if let exp = self.impExp {
                    exp.fulfill()
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isEventsEndpoint() {
                self.evePosted = true
                if let exp = self.eveExp {
                    exp.fulfill()
                }
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 500)
        }
    }
}
