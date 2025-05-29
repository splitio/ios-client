//
//  EventsStorageTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class PersistentEventsStorageTests: XCTestCase {
    var eventsStorage: PersistentEventsStorage!
    var eventDao: EventDaoStub!

    override func setUp() {
        eventDao = EventDaoStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.eventDao = eventDao
        eventsStorage = DefaultEventsStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider),
            expirationPeriod: 100)
    }

    func testPush() {
        createEvents().forEach { event in
            self.eventsStorage.push(event: event)
        }
        XCTAssertEqual(20, eventDao.insertedEvents.count)
    }

    func testPushMany() {
        eventsStorage.push(events: TestingHelper.createEvents(count: 20))
        eventsStorage.push(events: TestingHelper.createEvents(count: 20))
        eventsStorage.push(events: TestingHelper.createEvents(count: 20))

        XCTAssertEqual(60, eventDao.insertedEvents.count)
    }

    func testPop() {
        eventDao.getByEvents = createEvents()
        let popped = eventsStorage.pop(count: 100)

        XCTAssertEqual(eventDao.getByEvents.count, popped.count)
        XCTAssertEqual(eventDao.updatedEvents.count, popped.count)
        XCTAssertEqual(0, eventDao.updatedEvents.values.filter { $0 == StorageRecordStatus.active }.count)
    }

    func testDelete() {
        let events = createEvents()
        eventsStorage.delete(events)

        XCTAssertEqual(eventDao.deletedEvents.count, events.count)
    }

    func testSetActive() {
        let events = createEvents()

        eventsStorage.setActive(events)

        XCTAssertEqual(events.count, eventDao.updatedEvents.values.filter { $0 == StorageRecordStatus.active }.count)
        XCTAssertEqual(0, eventDao.updatedEvents.values.filter { $0 == StorageRecordStatus.deleted }.count)
    }

    override func tearDown() {}

    func createEvents() -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0 ..< 20 {
            let event = EventDTO(trafficType: "name", eventType: "type")
            event.storageId = UUID().uuidString
            event.key = "key1"
            event.eventTypeId = "type1"
            event.trafficTypeName = "name1"
            event.value = (i % 2 > 0 ? 1.0 : 0.0)
            event.timestamp = 1000
            event.properties = ["f": i]
            events.append(event)
        }
        return events
    }
}
