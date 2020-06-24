//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
public class DefaultSplitFactory: NSObject, SplitFactory {

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    private var defaultClient: SplitClient!
    private let defaultManager: SplitManager

    public var client: SplitClient {
        return defaultClient
    }

    public var manager: SplitManager {
        return defaultManager
    }

    public var version: String {
        return Version.sdk
    }

    init(apiKey: String, key: Key, config: SplitClientConfig) {
        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? config.defaultDataFolder

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        MetricManagerConfig.default.defaultDataFolderName = dataFolderName

        config.apiKey = apiKey
        let fileStorage = FileStorage(dataFolderName: dataFolderName)
        let splitCache = SplitCache(fileStorage: fileStorage)
        let manager = DefaultSplitManager(splitCache: splitCache)
        defaultManager = manager

        let mySegmentsCache = MySegmentsCache(matchingKey: key.matchingKey, fileStorage: fileStorage)

        let eventsManager = DefaultSplitEventsManager(config: config)
        eventsManager.start()

        let restClient = DefaultRestClient(endpointFactory: EndpointFactory(serviceEndpoints: config.serviceEndpoints,
                                                                            apiKey: apiKey, userKey: key.matchingKey))

        /// TODO: Remove this line when metrics refactor
        DefaultMetricsManager.shared.restClient = restClient
        let httpSplitFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache)

        let refreshableSplitFetcher = DefaultRefreshableSplitFetcher(
            splitChangeFetcher: httpSplitFetcher, splitCache: splitCache, interval: config.featuresRefreshRate,
            eventsManager: eventsManager)

        let mySegmentsFetcher = HttpMySegmentsFetcher(restClient: restClient, mySegmentsCache: mySegmentsCache)
        let refreshableMySegmentsFetcher = DefaultRefreshableMySegmentsFetcher(
            matchingKey: key.matchingKey, mySegmentsChangeFetcher: mySegmentsFetcher, mySegmentsCache: mySegmentsCache,
            interval: config.segmentsRefreshRate, eventsManager: eventsManager)

        super.init()

        let trackManager = buildTrackManager(splitConfig: config, fileStorage: fileStorage, restClient: restClient)
        let impressionsManager = buildImpressionsManager(splitConfig: config, fileStorage: fileStorage,
                                                         restClient: restClient)

        defaultClient = DefaultSplitClient(
            config: config, key: key, splitCache: splitCache, eventsManager: eventsManager, trackManager: trackManager,
            impressionsManager: impressionsManager, refreshableSplitFetcher: refreshableSplitFetcher,
            refreshableMySegmentsFetcher: refreshableMySegmentsFetcher, destroyHandler: {
                refreshableMySegmentsFetcher.stop()
                refreshableSplitFetcher.stop()
                impressionsManager.stop()
                trackManager.stop()
                manager.destroy()
        })

        eventsManager.getExecutorResources().setClient(client: defaultClient)
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        trackManager.start()
        impressionsManager.start()
    }

    private func buildTrackConfig(from splitConfig: SplitClientConfig) -> TrackManagerConfig {
        return TrackManagerConfig(
            firstPushWindow: splitConfig.eventsFirstPushWindow, pushRate: splitConfig.eventsPushRate,
            queueSize: splitConfig.eventsQueueSize, eventsPerPush: splitConfig.eventsPerPush,
            maxHitsSizeInBytes: splitConfig.maxEventsQueueMemorySizeInBytes)
    }

    private func buildImpressionsConfig(from splitConfig: SplitClientConfig) -> ImpressionManagerConfig {
        return ImpressionManagerConfig(pushRate: splitConfig.impressionRefreshRate,
                                       impressionsPerPush: splitConfig.impressionsChunkSize)
    }

    private func buildTrackManager(splitConfig: SplitClientConfig, fileStorage: FileStorage,
                                   restClient: RestClientTrackEvents) -> TrackManager {
        return DefaultTrackManager(config: buildTrackConfig(from: splitConfig),
                                   fileStorage: fileStorage, restClient: restClient)
    }

    private func buildImpressionsManager(splitConfig: SplitClientConfig, fileStorage: FileStorage,
                                         restClient: RestClientImpressions) -> ImpressionsManager {
        return DefaultImpressionsManager(config: buildImpressionsConfig(from: splitConfig), fileStorage: fileStorage,
                                         restClient: restClient)
    }
}
