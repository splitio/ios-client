//
//  EventsRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class EventsRecorderWorker: RecorderWorker {
    private let persistentEventsStorage: PersistentEventsStorage
    private let eventsRecorder: HttpEventsRecorder
    private let eventsPerPush: Int
    private let eventsSyncHelper: EventsRecorderSyncHelper?

    init(
        persistentEventsStorage: PersistentEventsStorage,
        eventsRecorder: HttpEventsRecorder,
        eventsPerPush: Int,
        eventsSyncHelper: EventsRecorderSyncHelper? = nil) {
        self.persistentEventsStorage = persistentEventsStorage
        self.eventsRecorder = eventsRecorder
        self.eventsPerPush = eventsPerPush
        self.eventsSyncHelper = eventsSyncHelper
    }

    func flush() {
        var rowCount = 0
        var failedEvents = [EventDTO]()
        repeat {
            let events = persistentEventsStorage.pop(count: eventsPerPush)
            rowCount = events.count
            if rowCount > 0 {
                Logger.d("Sending events")
                do {
                    _ = try eventsRecorder.execute(events)
                    // Removing sent events
                    persistentEventsStorage.delete(events)
                    Logger.i("Events posted successfully")
                } catch {
                    Logger.e("Events error: \(String(describing: error))")
                    failedEvents.append(contentsOf: events)
                }
            }
        } while rowCount == eventsPerPush
        // Activate non sent events to retry in next iteration
        persistentEventsStorage.setActive(failedEvents)
        if let syncHelper = eventsSyncHelper {
            syncHelper.updateAccumulator(
                count: failedEvents.count,
                bytes: failedEvents.reduce(0) { $0 + $1.sizeInBytes })
        }
    }
}
