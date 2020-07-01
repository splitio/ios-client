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

        let httpSplitFetcher = HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache)

        let refreshableSplitFetcher = DefaultRefreshableSplitFetcher(
            splitChangeFetcher: httpSplitFetcher, splitCache: splitCache, interval: config.featuresRefreshRate,
            cacheExpiration: config.cacheExpirationInSeconds, eventsManager: eventsManager)

        let mySegmentsFetcher = HttpMySegmentsFetcher(restClient: RestClient(), mySegmentsCache: mySegmentsCache)
        let refreshableMySegmentsFetcher = DefaultRefreshableMySegmentsFetcher(
            matchingKey: key.matchingKey, mySegmentsChangeFetcher: mySegmentsFetcher, mySegmentsCache: mySegmentsCache,
            interval: config.segmentsRefreshRate, eventsManager: eventsManager)

        super.init()

        let trackConfig = buildTrackConfig(from: config)
        let trackManager = DefaultTrackManager(config: trackConfig, fileStorage: fileStorage)

        let impressionsConfig = buildImpressionsConfig(from: config)
        let impressionsManager = DefaultImpressionsManager(config: impressionsConfig, fileStorage: fileStorage)

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
}
