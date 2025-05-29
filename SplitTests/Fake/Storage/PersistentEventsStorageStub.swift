//
//  PersistentEventsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentEventsStorageStub: PersistentEventsStorage {
    var storedEvents = [String: EventDTO]()
    var eventsStatus = [String: Int32]()

    func delete(_ events: [EventDTO]) {
        let ids = events.compactMap { $0.storageId }
        for uid in ids {
            storedEvents.removeValue(forKey: uid)
            eventsStatus.removeValue(forKey: uid)
        }
    }

    func pop(count: Int) -> [EventDTO] {
        let deleted = eventsStatus.filter { $0.value == StorageRecordStatus.deleted }.keys
        let poped = Array(storedEvents.values.filter { !deleted.contains($0.storageId ?? "") }.prefix(count))
        for event in poped {
            eventsStatus[event.storageId ?? ""] = StorageRecordStatus.deleted
        }
        return poped
    }

    func push(event: EventDTO) {
        if let eId = event.storageId {
            storedEvents[eId] = event
            eventsStatus[eId] = StorageRecordStatus.active
        }
    }

    func push(events: [EventDTO]) {
        for event in events {
            if let eId = event.storageId {
                storedEvents[eId] = event
                eventsStatus[eId] = StorageRecordStatus.active
            }
        }
    }

    func getCritical() -> [EventDTO] {
        return []
    }

    func setActive(_ events: [EventDTO]) {
        for event in events {
            if let eId = event.storageId {
                eventsStatus[eId] = StorageRecordStatus.active
            }
        }
    }
}
