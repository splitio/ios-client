//
//  SplitsWorkerFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 21/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Helper to allow unit testing of some features by stubbing it
protocol SyncWorkerFactory {
    func createRetryableSplitsUpdateWorker(splitChangeFetcher: SplitChangeFetcher,
                                           splitCache: SplitCacheProtocol,
                                           changeNumber: Int64,
                                           reconnectBackoffCounter: ReconnectBackoffCounter
    ) -> RetryableSyncWorker
}

class DefaultSyncWorkerFactory: SyncWorkerFactory {

    func createRetryableSplitsUpdateWorker(splitChangeFetcher: SplitChangeFetcher,
                                           splitCache: SplitCacheProtocol,
                                           changeNumber: Int64,
                                           reconnectBackoffCounter: ReconnectBackoffCounter
    ) -> RetryableSyncWorker {
        return RetryableSplitsUpdateWorker(splitChangeFetcher: splitChangeFetcher,
                                           splitCache: splitCache,
                                           changeNumber: changeNumber,
                                           reconnectBackoffCounter: reconnectBackoffCounter)
    }
}
