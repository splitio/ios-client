//
//  EventDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class EventDaoTests: XCTestCase {

    var eventDao: EventDao!

    override func setUp() {
        let queue = DispatchQueue(label: "event dao test")
        eventDao = CoreDataEventDao(coreDataHelper: IntegrationCoreDataHelper.get(databaseName: "test",
                                                                                  dispatchQueue: queue),
                                    dispatchQueue: queue)
        let events = createEvents()
        for event in events {
            eventDao.insert(event)
        }

    }

    func testInsertGet() {

        let loadedEvents = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedEvents.count)
    }

    func testUpdate() {

        let loadedEvents = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        eventDao.update(ids: loadedEvents.prefix(5).compactMap { return $0.storageId }, newStatus: StorageRecordStatus.deleted)
        let active = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    /// TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        eventDao.delete(Array(toDelete))
        let loadedEvents = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedEvents.count)
        XCTAssertEqual(0, loadedEvents.filter { notFound.contains($0.storageId)}.count)
    }

    func testLoadOutdated() {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedEvents = eventDao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedEvents1 = eventDao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedEvents.count)
        XCTAssertEqual(0, loadedEvents1.count)
    }

    override func tearDown() {

    }

    func createEvents() -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0..<10 {
            let event = EventDTO(trafficType: "name", eventType: "type")
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
