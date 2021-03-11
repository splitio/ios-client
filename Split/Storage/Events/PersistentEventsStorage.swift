//
//  PersistentEventsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentEventsStorage {
    func delete(_ events: [EventDTO])
    func pop(count: Int) -> [EventDTO]
    func push(event: EventDTO)
    func getCritical() -> [EventDTO]
    func setActive(_ events: [EventDTO])
}

class DefaultEventsStorage: PersistentEventsStorage {

    private let eventDao: EventDao
    private let expirationPeriod: Int64

    init(database: SplitDatabase, expirationPeriod: Int64) {

        self.eventDao = database.eventDao
        self.expirationPeriod = expirationPeriod
    }

    func pop(count: Int) -> [EventDTO] {
        let createdAt = Date().unixTimestamp() - self.expirationPeriod
        let events = eventDao.getBy(createdAt: createdAt, status: StorageRecordStatus.active, maxRows: count)
        eventDao.update(ids: events.compactMap { $0.storageId }, newStatus: StorageRecordStatus.deleted)
        return events
    }

    func push(event: EventDTO) {
        eventDao.insert(event)
    }

    func getCritical() -> [EventDTO] {
        // To be used in the future.
        return []
    }

    func setActive(_ events: [EventDTO]) {
        if events.count < 1 {
            return
        }
        eventDao.update(ids: events.compactMap { return $0.storageId }, newStatus: StorageRecordStatus.active)
    }

    func delete(_ events: [EventDTO]) {
        eventDao.delete(events)
    }
}
