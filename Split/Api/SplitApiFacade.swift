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
    let splitsFetcher: SplitChangeFetcher
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

        let splitsChangeFetcher: SplitChangeFetcher
            = HttpSplitChangeFetcher(restClient: restClient, splitCache: storageContainer.splitsCache,
                                     defaultQueryString: splitsQueryString)

        let mySegmentsFetcher: MySegmentsChangeFetcher
            = HttpMySegmentsFetcher(restClient: restClient, mySegmentsCache: storageContainer.mySegmentsCache)

        let backoffBase =  splitConfig.generalRetryBackoffBase

        let splitsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        let splitsSyncWorker = RetryableSplitsSyncWorker(splitChangeFetcher: splitsChangeFetcher,
                                                         splitCache: storageContainer.splitsCache,
                                                         cacheExpiration: splitConfig.cacheExpirationInSeconds,
                                                         eventsManager: eventsManager,
                                                         reconnectBackoffCounter: splitsBackoffCounter)

        let mySegmentsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        let mySegmentsWorker = RetryableMySegmentsSyncWorker(matchingKey: userKey,
                                                             mySegmentsChangeFetcher: mySegmentsFetcher,
                                                             mySegmentsCache: storageContainer.mySegmentsCache,
                                                             eventsManager: eventsManager,
                                                             reconnectBackoffCounter: mySegmentsBackoffCounter)

        let periodicSplitsSyncWorker = PeriodicSplitsSyncWorker(
            splitChangeFetcher: splitsChangeFetcher, splitCache: storageContainer.splitsCache,
            timer: DefaultPeriodicTimer(interval: splitConfig.featuresRefreshRate), eventsManager: eventsManager)

        let periodicMySegmentsSyncWorker = PeriodicMySegmentsSyncWorker(
            userKey: userKey, mySegmentsFetcher: mySegmentsFetcher, mySegmentsCache: storageContainer.mySegmentsCache,
            timer: DefaultPeriodicTimer(interval: splitConfig.segmentsRefreshRate), eventsManager: eventsManager)

        return SplitApiFacade(
            splitsFetcher: splitsChangeFetcher, impressionsManager: impressionsManager,
            trackManager: trackManager, splitsSyncWorker: splitsSyncWorker, mySegmentsSyncWorker: mySegmentsWorker,
            periodicSplitsSyncWorker: periodicSplitsSyncWorker,
            periodicMySegmentsSyncWorker: periodicMySegmentsSyncWorker,
            streamingHttpClient: streamingHttpClient)
    }
}
