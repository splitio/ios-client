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
}
