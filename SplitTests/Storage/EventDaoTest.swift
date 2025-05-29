//
//  EventDaoTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventDaoTest: XCTestCase {
    var eventDao: EventDao!
    var eventDaoAes128Cbc: EventDao!

    override func setUp() {
        let queue = DispatchQueue(label: "event dao test")
        eventDao = CoreDataEventDao(coreDataHelper: IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: queue))

        eventDaoAes128Cbc = CoreDataEventDao(
            coreDataHelper: IntegrationCoreDataHelper.get(
                databaseName: "test",
                dispatchQueue: queue),
            cipher: DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey))
        let events = createEvents()
        for event in events {
            eventDao.insert(event)
            eventDaoAes128Cbc.insert(event)
        }
    }

    func testInsertGetPlainText() {
        insertGet(dao: eventDao)
    }

    func testInsertGetAes128Cbc() {
        insertGet(dao: eventDaoAes128Cbc)
    }

    func insertGet(dao: EventDao) {
        let loadedEvents = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        XCTAssertEqual(10, loadedEvents.count)
    }

    func testInsertManyGetPlainText() {
        insertManyGet(dao: eventDao)
    }

    func testInsertManyGetAes128Cbc() {
        insertManyGet(dao: eventDaoAes128Cbc)
    }

    func insertManyGet(dao: EventDao) {
        dao.insert(TestingHelper.createEvents(count: 20))

        let loadedEvents = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 40)

        // Initial 10 + 20 here
        XCTAssertEqual(30, loadedEvents.count)
    }

    func testUpdatePlainText() {
        insertManyGet(dao: eventDao)
    }

    func testUpdateAes128Cbc() {
        insertManyGet(dao: eventDaoAes128Cbc)
    }

    func update(dao: EventDao) {
        let loadedEvents = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        dao.update(ids: loadedEvents.prefix(5).compactMap { $0.storageId }, newStatus: StorageRecordStatus.deleted)
        let active = dao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)
        let deleted = dao.getBy(createdAt: 200, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(5, active.count)
        XCTAssertEqual(5, deleted.count)
    }

    func testLoadOutdatedPlainText() {
        loadOutdated(dao: eventDao)
    }

    func testLoadOutdatedAes128Cbc() {
        loadOutdated(dao: eventDaoAes128Cbc)
    }

    func loadOutdated(dao: EventDao) {
        let timestamp = Date().unixTimestamp() + 10000
        let loadedEvents = dao.getBy(createdAt: timestamp, status: StorageRecordStatus.active, maxRows: 20)
        let loadedEvents1 = dao.getBy(createdAt: timestamp, status: StorageRecordStatus.deleted, maxRows: 20)

        XCTAssertEqual(0, loadedEvents.count)
        XCTAssertEqual(0, loadedEvents1.count)
    }

    func testDataIsEncryptedInDb() {
        let cipher = DefaultCipher(cipherKey: IntegrationHelper.dummyCipherKey)

        // Create two datos accessing the same db
        // One with encryption and the other without it
        let helper = IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue(label: "event dao test"))
        eventDao = CoreDataEventDao(coreDataHelper: helper)
        eventDaoAes128Cbc = CoreDataEventDao(
            coreDataHelper: helper,
            cipher: cipher)

        // create impressions and get one encrypted feature name
        let events = createEvents()

        // Insert encrypted impressions
        for event in events {
            eventDaoAes128Cbc.insert(event)
        }

        // load events and filter them by encrypted feature name
        let loadedEvent = getBy(coreDataHelper: helper)

        let event = try? Json.dynamicDecodeFrom(json: loadedEvent ?? "", to: EventDTO.self)

        XCTAssertNotNil(loadedEvent)
        XCTAssertFalse(loadedEvent?.contains("key1") ?? true)
        XCTAssertNil(event)
    }

    func getBy(coreDataHelper: CoreDataHelper) -> String? {
        var body: String? = nil
        coreDataHelper.performAndWait {
            let entities = coreDataHelper.fetch(
                entity: .event,
                where: nil,
                rowLimit: 1).compactMap { $0 as? EventEntity }
            if !entities.isEmpty {
                body = entities[0].body
            }
        }
        return body
    }

    // TODO: Check how to test delete in inMemoryDb
    func PausedtestDelete() {
        let toDelete = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20).prefix(5)

        eventDao.delete(Array(toDelete))
        let loadedEvents = eventDao.getBy(createdAt: 200, status: StorageRecordStatus.active, maxRows: 20)

        let notFound = Set(toDelete.map { $0.storageId })

        XCTAssertEqual(5, loadedEvents.count)
        XCTAssertEqual(0, loadedEvents.filter { notFound.contains($0.storageId) }.count)
    }

    func createEvents() -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0 ..< 10 {
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
