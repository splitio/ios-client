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

    func createRetryableMySegmentsSyncWorker(avoidCache: Bool) -> RetryableSyncWorker

    func createPeriodicMySegmentsSyncWorker() -> PeriodicSyncWorker

    func createPeriodicImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker

    func createImpressionsCountRecorderWorker() -> RecorderWorker

    func createPeriodicImpressionsCountRecorderWorker() -> PeriodicRecorderWorker

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker
}

class DefaultSyncWorkerFactory: SyncWorkerFactory {

    private let storageContainer: SplitStorageContainer
    private let apiFacade: SplitApiFacade
    private let splitConfig: SplitClientConfig
    private let splitChangeProcessor: SplitChangeProcessor
    private let userKey: String
    private let eventsManager: SplitEventsManager
    private let splitsFilterQueryString: String
    // TODO: Inject in constructor when real implementation
    private let telemetryProducer = InMemoryTelemetryStorage()

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
        return RetryableSplitsSyncWorker(splitFetcher: apiFacade.splitsFetcher,
                                         splitsStorage: storageContainer.splitsStorage,
                                         splitChangeProcessor: splitChangeProcessor,
                                         cacheExpiration: splitConfig.cacheExpirationInSeconds,
                                         defaultQueryString: splitsFilterQueryString,
                                         eventsManager: eventsManager,
                                         reconnectBackoffCounter: backoffCounter)
    }

    func createRetryableSplitsUpdateWorker(changeNumber: Int64,
                                           reconnectBackoffCounter: ReconnectBackoffCounter) -> RetryableSyncWorker {
        return RetryableSplitsUpdateWorker(splitsFetcher: apiFacade.splitsFetcher,
                                           splitsStorage: storageContainer.splitsStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           changeNumber: changeNumber, eventsManager: eventsManager,
                                           reconnectBackoffCounter: reconnectBackoffCounter)
    }

    func createRetryableMySegmentsSyncWorker(avoidCache: Bool) -> RetryableSyncWorker {

        let backoffBase =  splitConfig.generalRetryBackoffBase
        let mySegmentsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        return RetryableMySegmentsSyncWorker(userKey: userKey, mySegmentsFetcher: apiFacade.mySegmentsFetcher,
                                             mySegmentsStorage: storageContainer.mySegmentsStorage,
                                             telemetryProducer: telemetryProducer,
                                             eventsManager: eventsManager,
                                             reconnectBackoffCounter: mySegmentsBackoffCounter,
                                             avoidCache: avoidCache)
    }

    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker {
        return  PeriodicSplitsSyncWorker(
            splitFetcher: apiFacade.splitsFetcher, splitsStorage: storageContainer.splitsStorage,
            splitChangeProcessor: splitChangeProcessor,
            timer: DefaultPeriodicTimer(interval: splitConfig.featuresRefreshRate), eventsManager: eventsManager)
    }

    func createPeriodicMySegmentsSyncWorker() -> PeriodicSyncWorker {
        return PeriodicMySegmentsSyncWorker(
            userKey: userKey, mySegmentsFetcher: apiFacade.mySegmentsFetcher,
            mySegmentsStorage: storageContainer.mySegmentsStorage, telemetryProducer: telemetryProducer,
            timer: DefaultPeriodicTimer(interval: splitConfig.segmentsRefreshRate), eventsManager: eventsManager)
    }

    func createPeriodicImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        let impressionWorker = ImpressionsRecorderWorker(impressionsStorage: storageContainer.impressionsStorage,
                                                         impressionsRecorder: apiFacade.impressionsRecorder,
                                                         impressionsPerPush: Int(splitConfig.impressionsChunkSize),
                                                         impressionsSyncHelper: syncHelper)

        let timer = DefaultPeriodicTimer(deadline: 0, interval: splitConfig.impressionRefreshRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: impressionWorker)
    }

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker {
        return ImpressionsRecorderWorker(impressionsStorage: storageContainer.impressionsStorage,
                                         impressionsRecorder: apiFacade.impressionsRecorder,
                                         impressionsPerPush: Int(splitConfig.impressionsChunkSize),
                                         impressionsSyncHelper: syncHelper)
    }

    func createImpressionsCountRecorderWorker() -> RecorderWorker {
        return ImpressionsCountRecorderWorker(countsStorage: storageContainer.impressionsCountStorage,
                                              countsRecorder: apiFacade.impressionsCountRecorder)
    }

    func createPeriodicImpressionsCountRecorderWorker() -> PeriodicRecorderWorker {
        let recorderWorker = ImpressionsCountRecorderWorker(countsStorage: storageContainer.impressionsCountStorage,
                                                            countsRecorder: apiFacade.impressionsCountRecorder)
        let timer = DefaultPeriodicTimer(deadline: 0, interval: splitConfig.impressionsCountsRefreshRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: recorderWorker)
    }

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        let eventsWorker = EventsRecorderWorker(eventsStorage: storageContainer.eventsStorage,
                                                eventsRecorder: apiFacade.eventsRecorder,
                                                eventsPerPush: Int(splitConfig.eventsPerPush),
                                                eventsSyncHelper: syncHelper)

        let timer = DefaultPeriodicTimer(deadline: splitConfig.eventsFirstPushWindow,
                                         interval: splitConfig.eventsPushRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: eventsWorker)
    }

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker {
        return EventsRecorderWorker(eventsStorage: storageContainer.eventsStorage,
                                    eventsRecorder: apiFacade.eventsRecorder,
                                    eventsPerPush: Int(splitConfig.eventsPerPush),
                                    eventsSyncHelper: syncHelper)

    }

    func createTelemetryConfigRecorderWorker() -> RecorderWorker? {

        guard let telemetryStorage = storageContainer.telemetryStorage else {
            return nil
        }


        
        let rates = TelemetryRates(splits: splitConfig.featuresRefreshRate,
                                   mySegments: splitConfig.segmentsRefreshRate,
                                   impressions: splitConfig.impressionRefreshRate,
                                   events: splitConfig.eventsPushRate, telemetry: splitConfig.telemetryRefreshRate)


        let endpoints = splitConfig.serviceEndpoints
        let urlOverrides = TelemetryUrlOverrides(sdk: endpoints.isCustomSdkEndpoint,
                                                 events: endpoints.isCustomEventsEndpoint,
                                                 auth: endpoints.isCustomAuthServiceEndpoint,
                                                 stream: endpoints.isCustomStreamingEndpoint,
                                                 telemetry: endpoints.isCustomEventsEndpoint)


        let config = TelemetryConfig(streamingEnabled: splitConfig.streamingEnabled,
                                     rates: rates, urlOverrides: urlOverrides,
                                     impressionsQueueSize: splitConfig.impressionsQueueSize,
                                     eventsQueueSize: splitConfig.eventsQueueSize,
                                     impressionsMode: splitConfig.impressionsMode,
                                     impressionsListenerEnabled: splitConfig.impressionListener != nil,
                                     httpProxyDetected: splitConfig.isProxy(),
                                     activeFactories: telemetryStorage.,
                                     redundantFactories: <#T##Int64?#>,
                                     timeUntilReady: <#T##Int64#>,
                                     nonReadyUsages: <#T##Int64#>,
                                     integrations: nil, tags: nil)

        return TelemetryConfigRecorderWorker(configRecorder: <#T##HttpTelemetryConfigRecorder#>, telemetryConfig: <#T##TelemetryConfig#>: storageContainer.eventsStorage,
                                    eventsSyncHelper: syncHelper)

    }
}
