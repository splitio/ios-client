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
         reachabilityChecker: HostReachabilityChecker?,
         testDatabase: SplitDatabase? = nil) throws {
        super.init()

        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? config.defaultDataFolder

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        MetricManagerConfig.default.defaultDataFolderName = dataFolderName

        config.apiKey = apiKey
        let storageContainer = buildStorageContainer(userKey: key.matchingKey,
                                                     dataFolderName: dataFolderName,
                                                     testDatabase: testDatabase)

        let manager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        defaultManager = manager

        let eventsManager = DefaultSplitEventsManager(config: config)
        eventsManager.start()

        let splitsFilterQueryString = try filterBuilder.add(filters: config.sync.filters).build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: config.serviceEndpoints,
                                               apiKey: apiKey, userKey: key.matchingKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: httpClient ?? DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: reachabilityChecker ?? ReachabilityWrapper())

        /// TODO: Remove this line when metrics refactor
        DefaultMetricsManager.shared.restClient = restClient

        let trackManager = buildTrackManager(splitConfig: config, fileStorage: storageContainer.fileStorage,
                                             restClient: restClient)

        let apiFacadeBuilder = SplitApiFacade.builder().setUserKey(key.matchingKey).setSplitConfig(config)
            .setRestClient(restClient).setEventsManager(eventsManager)
            .setTrackManager(trackManager).setStorageContainer(storageContainer)
            .setSplitsQueryString(splitsFilterQueryString)

        if let httpClient = httpClient {
            _ = apiFacadeBuilder.setStreamingHttpClient(httpClient)
        }

        let apiFacade = apiFacadeBuilder.build()
        let splitFetcher = DefaultHttpSplitFetcher(restClient: restClient, metricsManager: DefaultMetricsManager.shared)

        let syncManager = SyncManagerBuilder().setUserKey(key.matchingKey).setStorageContainer(storageContainer)
            .setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade)
            .setSplitConfig(config).build()

        let impressionsFlushChecker = DefaultRecorderFlushChecker(maxQueueSize: config.impressionsQueueSize, maxQueueSizeInBytes: config.impressionsQueueSize)
        let impressionsSyncHelper = ImpressionsRecorderSyncHelper(impressionsStorage: storageContainer.impressionsStorage,
                                                                   accumulator: impressionsFlushChecker)
        let synchronizer = DefaultSynchronizer(splitConfig: config, splitApiFacade: apiFacade,
                                               splitStorageContainer: storageContainer,
                                               syncWorkerFactory: syncWorkerFactory, impressionsSyncHelper: impressionsSyncHelper)

        defaultClient = DefaultSplitClient(config: config, key: key, apiFacade: apiFacade,
                                           storageContainer: storageContainer, synchronizer: synchronizer, eventsManager: eventsManager) {
                syncManager.stop()
                manager.destroy()
        }

        eventsManager.getExecutorResources().setClient(client: defaultClient!)
        syncManager.start()
    }

    private func buildTrackConfig(from splitConfig: SplitClientConfig) -> TrackManagerConfig {
        return TrackManagerConfig(
            firstPushWindow: splitConfig.eventsFirstPushWindow, pushRate: splitConfig.eventsPushRate,
            queueSize: splitConfig.eventsQueueSize, eventsPerPush: splitConfig.eventsPerPush,
            maxHitsSizeInBytes: splitConfig.maxEventsQueueMemorySizeInBytes)
    }

    private func buildTrackManager(splitConfig: SplitClientConfig, fileStorage: FileStorageProtocol,
                                   restClient: RestClientTrackEvents) -> TrackManager {
        return DefaultTrackManager(config: buildTrackConfig(from: splitConfig),
                                   fileStorage: fileStorage, restClient: restClient)
    }

    private func buildStorageContainer(userKey: String,
                                       dataFolderName: String,
                                       testDatabase: SplitDatabase?) -> SplitStorageContainer {
        let fileStorage = FileStorage(dataFolderName: dataFolderName)

        var database: SplitDatabase?
        if testDatabase == nil {
            let semaphore = DispatchSemaphore(value: 0)
            database = CoreDataSplitDatabase(databaseName: dataFolderName) {
                semaphore.signal()
            }
            semaphore.wait()

        } else {
            database = testDatabase
        }

        guard let splitDatabase = database else {
            fatalError("Couldn't create split database")
        }

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistentSplitsStorage)

        let persistentMySegmentsStorage = DefaultPersistentMySegmentsStorage(userKey: userKey, database: splitDatabase)
        let mySegmentsStorage = DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage)

        let impressionsStorage = DefaultImpressionsStorage(database: splitDatabase,
                                                           expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)

        return SplitStorageContainer(fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     impressionsStorage: impressionsStorage)
    }
}
