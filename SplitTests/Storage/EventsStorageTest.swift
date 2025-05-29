//
//  EventsStorageTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventsStorageTest: XCTestCase {
    var persistentStorage: PersistentEventsStorageStub!

    override func setUp() {
        persistentStorage = PersistentEventsStorageStub()
    }

    func testStartDisabledPersistence() {
        let eventsStorage = MainEventsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createEvents(count: 10).forEach {
            eventsStorage.push($0)
        }

        let count = persistentStorage.storedEvents.count

        XCTAssertEqual(0, count)
    }

    func testStartEnabledPersistence() {
        let eventsStorage = MainEventsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: true)

        TestingHelper.createEvents(count: 10).forEach {
            eventsStorage.push($0)
        }

        let count = persistentStorage.storedEvents.count

        XCTAssertEqual(10, count)
    }

    func testEnablePersistence() {
        // When enabling persistence data should be persisted and
        // in memory cache cleared
        let eventsStorage = MainEventsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createEvents(count: 10).forEach {
            eventsStorage.push($0)
        }

        let countBeforeEnable = persistentStorage.storedEvents.count

        eventsStorage.enablePersistence(true)

        TestingHelper.createEvents(count: 10, randomId: true).forEach {
            eventsStorage.push($0)
        }

        let countAfterEnable = persistentStorage.storedEvents.count

        XCTAssertEqual(0, countBeforeEnable)
        XCTAssertEqual(20, countAfterEnable)
    }

    func testDisablePersistence() {
        // When enabling persistence data should be persisted and
        // in memory cache cleared
        let eventsStorage = MainEventsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: true)

        TestingHelper.createEvents(count: 10).forEach {
            eventsStorage.push($0)
        }

        let countBeforeDisable = persistentStorage.storedEvents.count

        eventsStorage.enablePersistence(false)

        TestingHelper.createEvents(count: 10, randomId: true).forEach {
            eventsStorage.push($0)
        }

        let countAfterDisable = persistentStorage.storedEvents.count

        XCTAssertEqual(10, countBeforeDisable)
        XCTAssertEqual(10, countAfterDisable)
    }

    func testClear() {
        let eventsStorage = MainEventsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createEvents(count: 10).forEach {
            eventsStorage.push($0)
        }

        eventsStorage.clearInMemory()

        eventsStorage.enablePersistence(true)

        let countAfterEnable = persistentStorage.storedEvents.count

        // Should be 0 because in memory cache was cleared
        // so no data was available to persist
        XCTAssertEqual(0, countAfterEnable)
    }
}
