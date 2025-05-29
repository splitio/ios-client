//
//  EventsSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 29-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol EventsSynchronizer {
    func start()
    func pause()
    func resume()
    func stop()
    func flush()
    func push(_ event: EventDTO)
    func destroy()
}

class DefaultEventsSynchronizer: EventsSynchronizer {
    private let syncWorkerFactory: SyncWorkerFactory
    private let eventsSyncHelper: EventsRecorderSyncHelper
    private let periodicEventsRecorderWorker: PeriodicRecorderWorker
    private let flusherEventsRecorderWorker: RecorderWorker
    private let telemetryProducer: TelemetryRuntimeProducer?

    init(
        syncWorkerFactory: SyncWorkerFactory,
        eventsSyncHelper: EventsRecorderSyncHelper,
        telemetryProducer: TelemetryRuntimeProducer?) {
        self.syncWorkerFactory = syncWorkerFactory
        self.flusherEventsRecorderWorker = syncWorkerFactory.createEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.periodicEventsRecorderWorker =
            syncWorkerFactory.createPeriodicEventsRecorderWorker(syncHelper: eventsSyncHelper)
        self.eventsSyncHelper = eventsSyncHelper
        self.telemetryProducer = telemetryProducer
    }

    func start() {
        periodicEventsRecorderWorker.start()
    }

    func pause() {
        periodicEventsRecorderWorker.pause()
    }

    func resume() {
        periodicEventsRecorderWorker.resume()
    }

    func stop() {
        periodicEventsRecorderWorker.stop()
    }

    func flush() {
        flusherEventsRecorderWorker.flush()
    }

    func push(_ event: EventDTO) {
        if eventsSyncHelper.pushAndCheckFlush(event) {
            flusherEventsRecorderWorker.flush()
            eventsSyncHelper.resetAccumulator()
        }
        telemetryProducer?.recordEventStats(type: .queued, count: 1)
    }

    func destroy() {
        periodicEventsRecorderWorker.destroy()
    }
}
