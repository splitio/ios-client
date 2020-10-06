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

    private var defaultClient: SplitClient?
    private var defaultManager: SplitManager?

    public var client: SplitClient {
        return defaultClient!
    }

    public var manager: SplitManager {
        return defaultManager!
    }

    public var version: String {
        return Version.sdk
    }

    init(apiKey: String, key: Key, config: SplitClientConfig) {
        super.init()

        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? config.defaultDataFolder

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        MetricManagerConfig.default.defaultDataFolderName = dataFolderName

        config.apiKey = apiKey
        let storageContainer = buildStorageContainer(userKey: key.matchingKey,
                                                     dataFolderName: dataFolderName)

        let manager = DefaultSplitManager(splitCache: storageContainer.splitsCache)
        defaultManager = manager

        let eventsManager = DefaultSplitEventsManager(config: config)
        eventsManager.start()

        let  endpointFactory = EndpointFactory(serviceEndpoints: config.serviceEndpoints,
                                               apiKey: apiKey, userKey: key.matchingKey)
        let restClient = DefaultRestClient(endpointFactory: endpointFactory)

        /// TODO: Remove this line when metrics refactor
        DefaultMetricsManager.shared.restClient = restClient

        let trackManager = buildTrackManager(splitConfig: config, fileStorage: storageContainer.fileStorage,
                                             restClient: restClient)
        let impressionsManager = buildImpressionsManager(splitConfig: config, fileStorage: storageContainer.fileStorage,
                                                         restClient: restClient)

        let apiFacade = SplitApiFacade.builder().setUserKey(key.matchingKey).setSplitConfig(config)
            .setRestClient(restClient).setEventsManager(eventsManager).setImpressionsManager(impressionsManager)
            .setTrackManager(trackManager).setStorageContainer(storageContainer).build()

        let syncManager = SyncManagerBuilder().setUserKey(key.matchingKey).setStorageContainer(storageContainer)
            .setRestClient(restClient).setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade)
            .setSplitConfig(config).build()

        defaultClient = DefaultSplitClient(
            config: config, key: key, apiFacade: apiFacade, storageContainer: storageContainer,
            eventsManager: eventsManager, destroyHandler: {
                syncManager.stop()
                manager.destroy()
        })

        eventsManager.getExecutorResources().setClient(client: defaultClient!)
        syncManager.start()
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

    private func buildTrackManager(splitConfig: SplitClientConfig, fileStorage: FileStorageProtocol,
                                   restClient: RestClientTrackEvents) -> TrackManager {
        return DefaultTrackManager(config: buildTrackConfig(from: splitConfig),
                                   fileStorage: fileStorage, restClient: restClient)
    }

    private func buildImpressionsManager(splitConfig: SplitClientConfig, fileStorage: FileStorageProtocol,
                                         restClient: RestClientImpressions) -> ImpressionsManager {
        return DefaultImpressionsManager(config: buildImpressionsConfig(from: splitConfig), fileStorage: fileStorage,
                                         restClient: restClient)
    }

    private func buildStorageContainer(userKey: String,
                                       dataFolderName: String) -> SplitStorageContainer {
        let fileStorage = FileStorage(dataFolderName: dataFolderName)
        let mySegmentsCache = MySegmentsCache(matchingKey: userKey, fileStorage: fileStorage)
        let splitsCache = SplitCache(fileStorage: fileStorage)
        return SplitStorageContainer(fileStorage: fileStorage,
                                     splitsCache: splitsCache,
                                     mySegmentsCache: mySegmentsCache)
    }
}
