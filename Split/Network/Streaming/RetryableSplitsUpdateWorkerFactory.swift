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

    func createRetryableSplitsSyncWorker() -> RetryableSyncWorker

    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker
    
    func createRetryableSplitsUpdateWorker(changeNumber: Int64,
                                           reconnectBackoffCounter: ReconnectBackoffCounter
    ) -> RetryableSyncWorker

    func createRetryableMySegmentsSyncWorker() -> RetryableSyncWorker
    
    func createPeriodicMySegmentsSyncWorker() -> PeriodicSyncWorker
    
    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper) -> PeriodicRecorderWorker
}

class DefaultSyncWorkerFactory: SyncWorkerFactory {

    private let storageContainer: SplitStorageContainer
    private let apiFacade: SplitApiFacade
    private let splitConfig: SplitClientConfig
    private let splitChangeProcessor: SplitChangeProcessor
    private let userKey: String
    private let eventsManager: SplitEventsManager
    private let splitsFilterQueryString: String
    
    
    init(userKey: String,
         splitConfig: SplitClientConfig,
         splitsFilterQueryString: String,
         apiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         splitChangeProcessor: SplitChangeProcessor,
         eventsManager: SplitEventsManager) {

        self.userKey = userKey
        self.splitConfig = splitConfig
        self.splitsFilterQueryString = splitsFilterQueryString
        self.apiFacade = apiFacade
        self.storageContainer = storageContainer
        self.splitChangeProcessor = splitChangeProcessor
        self.eventsManager = eventsManager
    }

    func createRetryableSplitsSyncWorker() -> RetryableSyncWorker {
        let backoffCounter = DefaultReconnectBackoffCounter(backoffBase: splitConfig.generalRetryBackoffBase)
        return RevampRetryableSplitsSyncWorker(splitFetcher: apiFacade.splitsFetcher,
                                        splitsStorage: storageContainer.splitsStorage,
                                                           splitChangeProcessor: splitChangeProcessor,
                                                           cacheExpiration: splitConfig.cacheExpirationInSeconds,
                                                           defaultQueryString: splitsFilterQueryString,
                                                           eventsManager: eventsManager,
                                                           reconnectBackoffCounter: backoffCounter)
    }


    func createRetryableSplitsUpdateWorker(changeNumber: Int64,
                                           reconnectBackoffCounter: ReconnectBackoffCounter) -> RetryableSyncWorker {
        return RevampRetryableSplitsUpdateWorker(splitsFetcher: apiFacade.splitsFetcher,
                                                 splitsStorage: storageContainer.splitsStorage,
                                                 splitChangeProcessor: splitChangeProcessor,
                                                 changeNumber: changeNumber,
                                                 reconnectBackoffCounter: reconnectBackoffCounter)
    }
    
    func createRetryableMySegmentsSyncWorker() -> RetryableSyncWorker {
        
        let backoffBase =  splitConfig.generalRetryBackoffBase
        let mySegmentsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        return RetryableMySegmentsSyncWorker(userKey: userKey, mySegmentsFetcher: apiFacade.mySegmentsFetcher,
                                             mySegmentsStorage: storageContainer.mySegmentsStorage,
                                             metricsManager: DefaultMetricsManager.shared,
                                             eventsManager: eventsManager,
                                             reconnectBackoffCounter: mySegmentsBackoffCounter)
    }
    
    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker {
        return  RevampPeriodicSplitsSyncWorker(
            splitFetcher: apiFacade.splitsFetcher, splitsStorage: storageContainer.splitsStorage,
            splitChangeProcessor: splitChangeProcessor,
            timer: DefaultPeriodicTimer(interval: splitConfig.featuresRefreshRate), eventsManager: eventsManager)
    }
    
    func createPeriodicMySegmentsSyncWorker() -> PeriodicSyncWorker {
        return PeriodicMySegmentsSyncWorker(
            userKey: userKey, mySegmentsFetcher: apiFacade.mySegmentsFetcher,
            mySegmentsStorage: storageContainer.mySegmentsStorage, metricsManager: DefaultMetricsManager.shared,
            timer: DefaultPeriodicTimer(interval: splitConfig.segmentsRefreshRate), eventsManager: eventsManager)
    }
    
    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper) -> PeriodicRecorderWorker {
        let impressionWorker = ImpressionsRecorderWorker(impressionsStorage: storageContainer.impressionsStorage,
                                                         impressionsRecorder: apiFacade.impressionsRecorder,
                                                         impressionsPerPush: Int(splitConfig.impressionsChunkSize))
        
        let timer = DefaultPeriodicTimer(deadline: 0, interval: splitConfig.impressionRefreshRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: impressionWorker)
    }
}
