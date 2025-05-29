//
//  EventDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class EventDaoStub: EventDao {
    var insertedEvents = [EventDTO]()
    var getByEvents = [EventDTO]()
    var updatedEvents = [String: Int32]()
    var deletedEvents = [EventDTO]()

    func insert(_ event: EventDTO) {
        insertedEvents.append(event)
    }

    func insert(_ event: [EventDTO]) {
        insertedEvents.append(contentsOf: event)
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [EventDTO] {
        return getByEvents
    }

    func update(ids: [String], newStatus: Int32) {
        ids.forEach {
            updatedEvents[$0] = newStatus
        }
    }

    func delete(_ events: [EventDTO]) {
        deletedEvents.append(contentsOf: events)
    }
}
