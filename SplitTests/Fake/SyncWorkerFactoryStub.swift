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

    private var retryableWorkerIndex = -1
    var retryableSplitsUpdateWorkers: [RetryableSyncWorker] = [RetryableSyncWorkerStub()]

    func createRetryableSplitsUpdateWorker(changeNumber: Int64,
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

    func createPeriodicImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        return periodicImpressionsRecorderWorker
    }

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker {
        return impressionsRecorderWorker
    }

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        return periodicEventsRecorderWorker
    }

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker {
        return eventsRecorderWorker
    }
}
