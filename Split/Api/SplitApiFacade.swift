//
//  SplitApiFacade.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct SplitApiFacade {
    static func builder() -> SplitApiFacadeBuilder {
        return SplitApiFacadeBuilder()
    }
    //let splitsFetcher: SplitChangeFetcher
    let impressionsManager: ImpressionsManager
    let trackManager: TrackManager
    let splitsSyncWorker: RetryableSyncWorker
    let mySegmentsSyncWorker: RetryableSyncWorker
    let periodicSplitsSyncWorker: PeriodicSyncWorker
    let periodicMySegmentsSyncWorker: PeriodicSyncWorker
    let streamingHttpClient: HttpClient?
}

class SplitApiFacadeBuilder {

    private var userKey: String?
    private var splitConfig: SplitClientConfig?
    private var eventsManager: SplitEventsManager?
    private var restClient: DefaultRestClient?
    private var impressionsManager: ImpressionsManager?
    private var trackManager: TrackManager?
    private var storageContainer: SplitStorageContainer?
    private var streamingHttpClient: HttpClient?
    private var splitsQueryString: String = ""

    func setUserKey(_ userKey: String) -> SplitApiFacadeBuilder {
        self.userKey = userKey
        return self
    }

    func setSplitConfig(_ splitConfig: SplitClientConfig) -> SplitApiFacadeBuilder {
        self.splitConfig = splitConfig
        return self
    }

    func setEventsManager(_ eventsManager: SplitEventsManager) -> SplitApiFacadeBuilder {
        self.eventsManager = eventsManager
        return self
    }

    func setRestClient(_ restClient: DefaultRestClient) -> SplitApiFacadeBuilder {
        self.restClient = restClient
        return self
    }

    func setImpressionsManager(_ impressionsManager: ImpressionsManager) -> SplitApiFacadeBuilder {
        self.impressionsManager = impressionsManager
        return self
    }

    func setTrackManager(_ trackManager: TrackManager) -> SplitApiFacadeBuilder {
        self.trackManager = trackManager
        return self
    }

    func setStorageContainer(_ storageContainer: SplitStorageContainer) -> SplitApiFacadeBuilder {
        self.storageContainer = storageContainer
        return self
    }

    func setStreamingHttpClient(_ httpClient: HttpClient) -> SplitApiFacadeBuilder {
        self.streamingHttpClient = httpClient
        return self
    }

    func setSplitsQueryString(_ queryString: String) -> SplitApiFacadeBuilder {
        self.splitsQueryString = queryString
        return self
    }

    func build() -> SplitApiFacade {

        guard let userKey = self.userKey,
            let splitConfig = self.splitConfig,
            let eventsManager = self.eventsManager,
            let restClient = self.restClient,
            let impressionsManager = self.impressionsManager,
            let trackManager = self.trackManager,
            let storageContainer = self.storageContainer
            else {
                fatalError("Some parameter is null when creating Split Api Facade")
        }

        let splitsFetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                                    metricsManager: DefaultMetricsManager.shared)

        let mySegmentsFetcher: HttpMySegmentsFetcher
            = DefaultHttpMySegmentsFetcher(restClient: restClient, metricsManager: DefaultMetricsManager.shared)

        let backoffBase =  splitConfig.generalRetryBackoffBase
        let splitChangeProcessor = DefaultSplitChangeProcessor()

        let splitsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        let splitsSyncWorker = RevampRetryableSplitsSyncWorker(splitFetcher: splitsFetcher,
                                                               splitsStorage: storageContainer.splitsStorage,
                                                               splitChangeProcessor: splitChangeProcessor,
                                                         cacheExpiration: splitConfig.cacheExpirationInSeconds,
                                                         defaultQueryString: splitsQueryString,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: splitsBackoffCounter)

        let mySegmentsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        let mySegmentsWorker = RetryableMySegmentsSyncWorker(userKey: userKey, mySegmentsFetcher: mySegmentsFetcher,
                                                             mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                             metricsManager: DefaultMetricsManager.shared,
                                                             eventsManager: eventsManager,
                                                             reconnectBackoffCounter: mySegmentsBackoffCounter)

        let periodicSplitsSyncWorker = RevampPeriodicSplitsSyncWorker(
            splitFetcher: splitsFetcher, splitsStorage: storageContainer.splitsStorage,
            splitChangeProcessor: splitChangeProcessor,
            timer: DefaultPeriodicTimer(interval: splitConfig.featuresRefreshRate), eventsManager: eventsManager)

        let periodicMySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(
            userKey: userKey, mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: storageContainer.mySegmentsStorage, metricsManager: DefaultMetricsManager.shared,
            timer: DefaultPeriodicTimer(interval: splitConfig.segmentsRefreshRate), eventsManager: eventsManager)

        return SplitApiFacade(
            //splitsFetcher: splitsChangeFetcher,
            impressionsManager: impressionsManager,
            trackManager: trackManager, splitsSyncWorker: splitsSyncWorker, mySegmentsSyncWorker: mySegmentsWorker,
            periodicSplitsSyncWorker: periodicSplitsSyncWorker,
            periodicMySegmentsSyncWorker: periodicMySegmentsSyncWorker,
            streamingHttpClient: streamingHttpClient)
    }
}
