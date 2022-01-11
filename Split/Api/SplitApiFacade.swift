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

    let splitsFetcher: HttpSplitFetcher
    let mySegmentsFetcher: HttpMySegmentsFetcher
    let impressionsRecorder: HttpImpressionsRecorder
    let impressionsCountRecorder: HttpImpressionsCountRecorder
    let eventsRecorder: HttpEventsRecorder
    let streamingHttpClient: HttpClient?
    let sseAuthenticator: SseAuthenticator
    let telemetryConfigRecorder: HttpTelemetryConfigRecorder?
    let telemetryStatsRecorder: HttpTelemetryStatsRecorder?
}

class SplitApiFacadeBuilder {

    private var userKey: String?
    private var splitConfig: SplitClientConfig?
    private var eventsManager: SplitEventsManager?
    private var restClient: SplitApiRestClient?
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

    func setRestClient(_ restClient: SplitApiRestClient) -> SplitApiFacadeBuilder {
        self.restClient = restClient
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

        guard let restClient = self.restClient
            else {
                fatalError("Some parameter is null when creating Split Api Facade")
        }

        // TODO: Replace in real implementatyion
        let telemetryProducer = InMemoryTelemetryStorage()
        let splitsFetcher
            = DefaultHttpSplitFetcher(restClient: restClient,
                                      syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let mySegmentsFetcher: HttpMySegmentsFetcher
            = DefaultHttpMySegmentsFetcher(restClient: restClient,
                                           syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let impressionsRecorder
            = DefaultHttpImpressionsRecorder(restClient: restClient,
                                             syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let impressionsCountRecorder
            = DefaultHttpImpressionsCountRecorder(restClient: restClient,
                                                  syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let eventsRecorder
            = DefaultHttpEventsRecorder(restClient: restClient,
                                        syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let sseAuthenticator
            = DefaultSseAuthenticator(restClient: restClient)

        let telemetryConfigRecorder
            = DefaultHttpTelemetryConfigRecorder(restClient: restClient,
                                                 syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        let telemetryStatsRecorder
            = DefaultHttpTelemetryStatsRecorder(restClient: restClient,
                                                syncHelper: DefaultSyncHelper(telemetryProducer: telemetryProducer))

        return SplitApiFacade(splitsFetcher: splitsFetcher, mySegmentsFetcher: mySegmentsFetcher,
                              impressionsRecorder: impressionsRecorder,
                              impressionsCountRecorder: impressionsCountRecorder,
                              eventsRecorder: eventsRecorder, streamingHttpClient: self.streamingHttpClient,
                              sseAuthenticator: sseAuthenticator,
                              telemetryConfigRecorder: telemetryConfigRecorder,
                              telemetryStatsRecorder: telemetryStatsRecorder)
    }
}
