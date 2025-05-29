//
//  MySegmentsSyncWorkerFactoryStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsSyncWorkerFactoryStub: MySegmentsSyncWorkerFactory {
    private var mySegmentsSyncWorkers = [String: RetryableMySegmentsSyncWorkerStub]()
    var periodicMySegmentsSyncWorker = PeriodicSyncWorkerStub()

    func createRetryableMySegmentsSyncWorker(
        forKey key: String,
        avoidCache: Bool,
        eventsManager: SplitEventsManager,
        changeNumbers: SegmentsChangeNumber?) -> RetryableSyncWorker {
        return mySegmentsSyncWorkers["\(key)_\(avoidCache)"] ?? RetryableMySegmentsSyncWorkerStub()
    }

    func createPeriodicMySegmentsSyncWorker(
        forKey key: String,
        eventsManager: SplitEventsManager) -> PeriodicSyncWorker {
        return periodicMySegmentsSyncWorker
    }

    func addMySegmentWorker(
        _ worker: RetryableMySegmentsSyncWorkerStub,
        forKey key: String,
        avoidCache: Bool) {
        mySegmentsSyncWorkers["\(key)_\(avoidCache)"] = worker
    }
}
