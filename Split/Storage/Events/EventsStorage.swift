//
//  EventsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 25-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol EventsStorage {
    func enablePersistence(_ enable: Bool)
    func push(_ event: EventDTO)
    func clearInMemory()
}

// TODO: Rename persistent and this one
class MainEventsStorage: EventsStorage {
    private let persistentStorage: PersistentEventsStorage
    private let events = SynchronizedList<EventDTO>()
    private let isPersistenceEnabled: Atomic<Bool>

    init(persistentStorage: PersistentEventsStorage,
         persistenceEnabled: Bool = true) {
        self.persistentStorage = persistentStorage
        self.isPersistenceEnabled = Atomic(persistenceEnabled)
    }

    func enablePersistence(_ enable: Bool) {
        // Here we should save all events
        isPersistenceEnabled.set(enable)
        if enable {
            persistentStorage.push(events: events.takeAll())
        }
    }

    func push(_ event: EventDTO) {
        if isPersistenceEnabled.value {
            persistentStorage.push(event: event)
            return
        }
        events.append(event)
    }

    func clearInMemory() {
        events.removeAll()
    }
}
