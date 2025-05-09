//
//  SyncWorkerFactoryStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 21/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SyncWorkerFactoryStub: SyncWorkerFactory {

    var impressionsRecorderWorker = RecorderWorkerStub()
    var periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
    var eventsRecorderWorker = RecorderWorkerStub()
    var periodicEventsRecorderWorker = PeriodicRecorderWorkerStub()
    var splitsSyncWorker = RetryableSyncWorkerStub()
    var mySegmentsSyncWorker = RetryableSyncWorkerStub()
    var periodicSplitsSyncWorker = PeriodicSyncWorkerStub()
    var periodicMySegmentsSyncWorker = PeriodicSyncWorkerStub()
    var periodicImpressionsCountRecorderWorker = PeriodicRecorderWorkerStub()
    var impressionsCountRecorderWorker = RecorderWorkerStub()
    var telemetryConfigRecorderWorker = RecorderWorkerStub()
    var telemetryStatsRecorderWorker = RecorderWorkerStub()
    var periodicTelemetryStatsRecorderWorker = PeriodicRecorderWorkerStub()
    var uniqueKeysRecorderWorker = RecorderWorkerStub()
    var periodicUniqueKeysRecorderWorker = PeriodicRecorderWorkerStub()

    private var retryableWorkerIndex = -1
    var retryableSplitsUpdateWorkers: [RetryableSyncWorker] = [RetryableSyncWorkerStub()]

    func createRetryableSplitsUpdateWorker(changeNumber: SplitsUpdateChangeNumber,
                                           reconnectBackoffCounter: ReconnectBackoffCounter
    ) -> RetryableSyncWorker {

        if retryableWorkerIndex < retryableSplitsUpdateWorkers.count - 1{
            retryableWorkerIndex+=1
        }

        return retryableSplitsUpdateWorkers[retryableWorkerIndex]
    }

    func createRetryableSplitsSyncWorker() -> RetryableSyncWorker {
        return splitsSyncWorker
    }

    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker {
        return periodicSplitsSyncWorker
    }

    func createRetryableMySegmentsSyncWorker(avoidCache: Bool) -> RetryableSyncWorker {
        return mySegmentsSyncWorker
    }

    func createPeriodicMySegmentsSyncWorker() -> PeriodicSyncWorker {
        return periodicMySegmentsSyncWorker
    }

    func createPeriodicImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker? {
        return periodicImpressionsRecorderWorker
    }

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker? {
        return impressionsRecorderWorker
    }

    func createPeriodicImpressionsCountRecorderWorker() -> PeriodicRecorderWorker {
        return periodicImpressionsCountRecorderWorker
    }

    func createImpressionsCountRecorderWorker() -> RecorderWorker {
        return impressionsCountRecorderWorker
    }

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        return periodicEventsRecorderWorker
    }

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker {
        return eventsRecorderWorker
    }

    func createTelemetryConfigRecorderWorker() -> RecorderWorker? {
        return telemetryConfigRecorderWorker
    }

    func createTelemetryStatsRecorderWorker() -> RecorderWorker? {
        return telemetryStatsRecorderWorker
    }

    func createPeriodicTelemetryStatsRecorderWorker() -> PeriodicRecorderWorker? {
        return periodicTelemetryStatsRecorderWorker
    }

    func createUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> RecorderWorker {
        return uniqueKeysRecorderWorker
    }

    func createPeriodicUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> PeriodicRecorderWorker {
        return periodicUniqueKeysRecorderWorker
    }
}
