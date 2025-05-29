//
//  UserConsentManagerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class UserConsentManagerTest: XCTestCase {
    var userConsentManager: UserConsentManager!
    var config: SplitClientConfig!
    var impressionsStorage: ImpressionsStorageStub!
    var eventsStorage: EventsStorageStub!
    var syncManager: SyncManagerStub!
    var eventsTracker: EventsTrackerStub!
    var impressionsTracker: ImpressionsTrackerStub!

    func testSetGranted() {
        createUserConsentManager(status: .unknown) // Init to unknown
        let exp = XCTestExpectation()
        syncManager.setupUserConsentExp = exp
        eventsTracker.isTrackingEnabled = false

        userConsentManager.set(.granted)

        // Wait setup because is async
        wait(for: [exp], timeout: 5.0)

        XCTAssertEqual(UserConsent.granted, config.userConsent)
        XCTAssertTrue(eventsTracker.isTrackingEnabled)
        XCTAssertTrue(impressionsTracker.isTrackingEnabled)
        XCTAssertTrue(syncManager.setupUserConsentCalled)
        XCTAssertEqual(.granted, syncManager.setupUserConsentValue ?? .unknown)
    }

    func testSetDeclined() {
        createUserConsentManager(status: .granted) // Init to unknown
        let exp = XCTestExpectation()
        syncManager.setupUserConsentExp = exp
        eventsTracker.isTrackingEnabled = false

        userConsentManager.set(.declined)

        // Wait setup because is async
        wait(for: [exp], timeout: 5.0)

        XCTAssertEqual(UserConsent.declined, config.userConsent)
        XCTAssertFalse(eventsTracker.isTrackingEnabled)
        XCTAssertFalse(impressionsTracker.isTrackingEnabled)
        XCTAssertTrue(syncManager.setupUserConsentCalled)
        XCTAssertEqual(.declined, syncManager.setupUserConsentValue ?? .unknown)
    }

    func testSetUnknown() {
        createUserConsentManager(status: .granted) // Init to unknown
        let exp = XCTestExpectation()
        syncManager.setupUserConsentExp = exp
        eventsTracker.isTrackingEnabled = false

        userConsentManager.set(.unknown)

        // Wait setup because is async
        wait(for: [exp], timeout: 5.0)

        XCTAssertEqual(UserConsent.unknown, config.userConsent)
        XCTAssertTrue(eventsTracker.isTrackingEnabled)
        XCTAssertTrue(impressionsTracker.isTrackingEnabled)
        XCTAssertTrue(syncManager.setupUserConsentCalled)
        XCTAssertEqual(.unknown, syncManager.setupUserConsentValue ?? .granted)
    }

    private func createUserConsentManager(status: UserConsent) {
        config = SplitClientConfig()
        config.userConsent = status
        let storageContainer = TestingHelper.createStorageContainer()
        syncManager = SyncManagerStub()
        eventsTracker = EventsTrackerStub()
        impressionsTracker = ImpressionsTrackerStub()
        impressionsStorage = (storageContainer.impressionsStorage as? ImpressionsStorageStub)!
        eventsStorage = (storageContainer.eventsStorage as? EventsStorageStub)!
        userConsentManager = DefaultUserConsentManager(
            splitConfig: config,
            storageContainer: storageContainer,
            syncManager: syncManager,
            eventsTracker: eventsTracker,
            impressionsTracker: impressionsTracker)
    }
}
