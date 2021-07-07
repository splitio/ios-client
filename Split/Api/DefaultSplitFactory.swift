//
//  SplitFactory.swift
//  Split
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
    private let filterBuilder = FilterBuilder()

    public var client: SplitClient {
        return defaultClient!
    }

    public var manager: SplitManager {
        return defaultManager!
    }

    public var version: String {
        return Version.sdk
    }

    init(apiKey: String, key: Key, config: SplitClientConfig, httpClient: HttpClient?,
         reachabilityChecker: HostReachabilityChecker?, testDatabase: SplitDatabase? = nil) throws {
        super.init()

        let eventsManager = DefaultSplitEventsManager(config: config)

        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? config.defaultDataFolder

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        MetricManagerConfig.default.defaultDataFolderName = dataFolderName

        config.apiKey = apiKey
        let storageContainer = try SplitFactoryHelper.buildStorageContainer(
            userKey: key.matchingKey, dataFolderName: dataFolderName, testDatabase: testDatabase)

        LegacyStorageCleaner.deleteFiles(fileStorage: storageContainer.fileStorage, userKey: key.matchingKey)

        let manager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        defaultManager = manager

        let splitsFilterQueryString = try filterBuilder.add(filters: config.sync.filters).build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: config.serviceEndpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: httpClient ?? DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: reachabilityChecker ?? ReachabilityWrapper())

        /// TODO: Remove this line when metrics refactor
        DefaultMetricsManager.shared.restClient = restClient

        let apiFacadeBuilder = SplitApiFacade.builder().setUserKey(key.matchingKey)
            .setSplitConfig(config).setRestClient(restClient).setEventsManager(eventsManager)
            .setStorageContainer(storageContainer).setSplitsQueryString(splitsFilterQueryString)

        if let httpClient = httpClient {
            _ = apiFacadeBuilder.setStreamingHttpClient(httpClient)
        }

        let apiFacade = apiFacadeBuilder.build()

        let impressionsFlushChecker = DefaultRecorderFlushChecker(maxQueueSize: config.impressionsQueueSize,
                                                                  maxQueueSizeInBytes: config.impressionsQueueSize)

        let impressionsSyncHelper = ImpressionsRecorderSyncHelper(
            impressionsStorage: storageContainer.impressionsStorage, accumulator: impressionsFlushChecker)

        let eventsFlushChecker
            = DefaultRecorderFlushChecker(maxQueueSize: Int(config.eventsQueueSize),
                                          maxQueueSizeInBytes: config.maxEventsQueueMemorySizeInBytes)
        let eventsSyncHelper = EventsRecorderSyncHelper(eventsStorage: storageContainer.eventsStorage,
                                                        accumulator: eventsFlushChecker)

        let syncWorkerFactory = DefaultSyncWorkerFactory(userKey: key.matchingKey,
                                                         splitConfig: config,
                                                         splitsFilterQueryString: splitsFilterQueryString,
                                                         apiFacade: apiFacade,
                                                         storageContainer: storageContainer,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         eventsManager: eventsManager)

        let synchronizer = DefaultSynchronizer(splitConfig: config, splitApiFacade: apiFacade,
                                               splitStorageContainer: storageContainer,
                                               syncWorkerFactory: syncWorkerFactory,
                                               impressionsSyncHelper: impressionsSyncHelper,
                                               eventsSyncHelper: eventsSyncHelper,
                                               splitsFilterQueryString: splitsFilterQueryString,
                                               splitEventsManager: eventsManager)

        let syncManager = SyncManagerBuilder().setUserKey(key.matchingKey).setStorageContainer(storageContainer)
            .setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade).setSynchronizer(synchronizer)
            .setSplitConfig(config).build()

        setupBgSync(config: config, apiKey: apiKey, userKey: key.matchingKey)

        defaultClient = DefaultSplitClient(config: config, key: key, apiFacade: apiFacade,
                                           storageContainer: storageContainer,
                                           synchronizer: synchronizer, eventsManager: eventsManager) {
            syncManager.stop()
            manager.destroy()
            eventsManager.stop()
            storageContainer.mySegmentsStorage.destroy()
            storageContainer.splitsStorage.destroy()
        }

        eventsManager.start()
        eventsManager.executorResources.client = defaultClient
        syncManager.start()
    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
    }
}
