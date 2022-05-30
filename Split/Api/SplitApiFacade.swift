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
    let impressionsRecorder: HttpImpressionsRecorder?
    let impressionsCountRecorder: HttpImpressionsCountRecorder?
    let eventsRecorder: HttpEventsRecorder
    let streamingHttpClient: HttpClient?
    let sseAuthenticator: SseAuthenticator
    let telemetryConfigRecorder: HttpTelemetryConfigRecorder?
    let telemetryStatsRecorder: HttpTelemetryStatsRecorder?
    let uniqueKeysRecorder: HttpUniqueKeysRecorder?
}

class SplitApiFacadeBuilder {

    private var userKey: String?
    private var splitConfig: SplitClientConfig?
    private var eventsManager: SplitEventsManager?
    private var restClient: SplitApiRestClient?
    private var storageContainer: SplitStorageContainer?
    private var streamingHttpClient: HttpClient?
    private var splitsQueryString: String = ""
    private var telemetryStorage: TelemetryStorage?

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

    func setTelemetryStorage(_ telemetryStorage: TelemetryStorage) -> SplitApiFacadeBuilder {
        self.telemetryStorage = telemetryStorage
        return self
    }

    func build() throws -> SplitApiFacade {

        guard let restClient = self.restClient else {
            throw GenericError.nullValueInApiFacade
        }

        let splitsFetcher
            = DefaultHttpSplitFetcher(restClient: restClient,
                                      syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))

        let mySegmentsFetcher: HttpMySegmentsFetcher
            = DefaultHttpMySegmentsFetcher(restClient: restClient,
                                           syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))

        let eventsRecorder
            = DefaultHttpEventsRecorder(restClient: restClient,
                                        syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))

        let sseAuthenticator
            = DefaultSseAuthenticator(restClient: restClient,
                                      syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))

        var telemetryConfigRecorder: HttpTelemetryConfigRecorder?
        var telemetryStatsRecorder: HttpTelemetryStatsRecorder?
        if splitConfig?.isTelemetryEnabled ?? false {
            telemetryConfigRecorder
            = DefaultHttpTelemetryConfigRecorder(restClient: restClient,
                                                 syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))

            telemetryStatsRecorder
            = DefaultHttpTelemetryStatsRecorder(restClient: restClient,
                                                syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))
        }

        return SplitApiFacade(splitsFetcher: splitsFetcher, mySegmentsFetcher: mySegmentsFetcher,
                              impressionsRecorder: getImpressionsRecorder(restClient: restClient),
                              impressionsCountRecorder: getImpressionsCountRecorder(restClient: restClient),
                              eventsRecorder: eventsRecorder, streamingHttpClient: self.streamingHttpClient,
                              sseAuthenticator: sseAuthenticator,
                              telemetryConfigRecorder: telemetryConfigRecorder,
                              telemetryStatsRecorder: telemetryStatsRecorder,
                              uniqueKeysRecorder: getUniqueKeysRecorder(restClient: restClient))
    }

    private func getImpressionsRecorder(restClient: RestClientImpressions) -> HttpImpressionsRecorder? {
        if impressionsMode() == .optimized ||
            impressionsMode() == .debug {
            return DefaultHttpImpressionsRecorder(restClient: restClient,
                                             syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))
        }
        return nil
    }

    private func getImpressionsCountRecorder(restClient: RestClientImpressionsCount) -> HttpImpressionsCountRecorder? {
        if impressionsMode() == .optimized ||
            impressionsMode() == .none {
            let syncHelper = DefaultSyncHelper(telemetryProducer: telemetryStorage)
            return  DefaultHttpImpressionsCountRecorder(restClient: restClient,
                                                      syncHelper: syncHelper)
        }
        return nil
    }

    private func getUniqueKeysRecorder(restClient: RestClientUniqueKeys) -> HttpUniqueKeysRecorder? {
        if impressionsMode() == .none {
            return DefaultHttpUniqueKeysRecorder(restClient: restClient,
                                                 syncHelper: DefaultSyncHelper(telemetryProducer: telemetryStorage))
        }
        return nil
    }

    private func impressionsMode() -> ImpressionsMode {
        return splitConfig?.finalImpressionsMode ?? .optimized
    }

}
