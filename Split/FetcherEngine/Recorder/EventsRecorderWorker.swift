//
//  EventsRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class EventsRecorderWorker: RecorderWorker {

    private let eventsStorage: PersistentEventsStorage
    private let eventsRecorder: HttpEventsRecorder
    private let eventsPerPush: Int
    private let eventsSyncHelper: EventsRecorderSyncHelper?

    init(eventsStorage: PersistentEventsStorage,
         eventsRecorder: HttpEventsRecorder,
         eventsPerPush: Int,
         eventsSyncHelper: EventsRecorderSyncHelper? = nil) {

        self.eventsStorage = eventsStorage
        self.eventsRecorder = eventsRecorder
        self.eventsPerPush = eventsPerPush
        self.eventsSyncHelper = eventsSyncHelper
    }

    func flush() {
        var rowCount = 0
        var failedEvents = [EventDTO]()
        repeat {
            let events = eventsStorage.pop(count: eventsPerPush)
            if events.count == 0 {
                return
            }
            rowCount = events.count
            Logger.d("Sending events")

            do {
                _ = try eventsRecorder.execute(events)
                // Removing sent events
                eventsStorage.delete(events)
                Logger.d("Event posted successfully")
            } catch let error {
                Logger.e("Event error: \(String(describing: error))")
                failedEvents.append(contentsOf: events)
            }
        } while rowCount == eventsPerPush
        // Activate non sent events to retry in next iteration
        eventsStorage.setActive(failedEvents)
        eventsStorage.setActive(failedEvents)
        if let syncHelper = eventsSyncHelper {
            syncHelper.updateAccumulator(count: failedEvents.count,
                                         bytes: failedEvents.reduce(0, { $0 + $1.sizeInBytes }))
        }
    }
}
