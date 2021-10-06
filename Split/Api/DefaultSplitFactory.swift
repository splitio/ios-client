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

    init(apiKey: String,
         key: Key,
         config: SplitClientConfig,
         httpClient: HttpClient?,
         reachabilityChecker: HostReachabilityChecker?,
         testDatabase: SplitDatabase? = nil,
         notificationHelper: NotificationHelper? = nil) throws {
        super.init()

        let components = ServiceLocator(splitClientConfig: config,
                                              apiKey: apiKey,
                                              userKey: key.matchingKey)

        // Creating Events Manager first speeds up init process
        let eventsManager = components.getSplitEventsManager()

        // Setup metrics
        setupMetrics(splitClientConfig: config)

        //
        let databaseName = SplitDatabaseHelper.databaseName(apiKey: apiKey) ?? config.defaultDataFolder
        SplitDatabaseHelper.renameDatabaseFromLegacyName(name: databaseName, apiKey: apiKey)

        let storageContainer = try components.getStorageContainer(databaseName: databaseName, testDatabase: testDatabase)

        LegacyStorageCleaner.deleteFiles(fileStorage: storageContainer.fileStorage, userKey: key.matchingKey)

        defaultManager = try components.getSplitManager()

        let  endpointFactory = try components.getEndpointFactory(filterBuilder: FilterBuilder())

        let restClient = DefaultRestClient(httpClient: httpClient ?? DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: reachabilityChecker ?? ReachabilityWrapper())

        /// TODO: Remove this line when metrics refactor
        DefaultMetricsManager.shared.restClient = restClient
        let splitsFilterQueryString = ""// filter here
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
            .setNotificationHelper(notificationHelper ?? DefaultNotificationHelper.instance)
            .setSplitConfig(config).build()

        setupBgSync(config: config, apiKey: apiKey, userKey: key.matchingKey)

        defaultClient = DefaultSplitClient(config: config, key: key, apiFacade: apiFacade,
                                           storageContainer: storageContainer,
                                           synchronizer: synchronizer, eventsManager: eventsManager) { [weak self] in

            syncManager.stop()
            if let self = self, let manager = self.defaultManager as? Destroyable {
                manager.destroy()
            }
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

    private func setupMetrics(splitClientConfig: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(splitClientConfig.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = splitClientConfig.metricsPushRate
    }
}

class ServiceLocator {

    private let apiKey: String
    private let userKey: String
    private let splitClientConfig: SplitClientConfig
    private var splitsFilterQueryString = ""

    private var services: [String: Any] = [:]

    init(splitClientConfig: SplitClientConfig, apiKey: String, userKey: String) {
        self.splitClientConfig = splitClientConfig
        self.apiKey = apiKey
        self.userKey = userKey
    }

    private func get<T>(for classType: T) -> Any? {
        let className = String(describing: classType.self)
        // If component exists, return it
        return services[className]
    }

    // This function is implemented using generics
    // because this way type(of: component) returns the original
    // static type.
    // If using Any instead of T we'd get the dynamic type
    private func add<T>(component: T) {
        let className = String(describing: type(of: component))
        services[className] = component
    }

    func getSplitEventsManager() -> SplitEventsManager {
        if let obj = get(for: SplitEventsManager.self) as? SplitEventsManager {
            return obj
        }
        let component: SplitEventsManager = DefaultSplitEventsManager(config: splitClientConfig)
        add(component: component)
        return component
    }

    func getStorageContainer(databaseName: String,
                             testDatabase: SplitDatabase?) throws -> SplitStorageContainer {

        if let obj = get(for: SplitStorageContainer.self) as? SplitStorageContainer {
            return obj
        }
        let component: SplitStorageContainer = try SplitDatabaseHelper.buildStorageContainer(userKey: userKey,
                                                                       databaseName: databaseName,
                                                                       testDatabase: testDatabase)
        add(component: component)
        return component
    }

    func getSplitManager() throws -> SplitManager {
        if let obj = get(for: SplitManager.self) as? SplitManager {
            return obj
        }
        guard let storageContainer = get(for: SplitStorageContainer.self) as? SplitStorageContainer else {
            throw ComponentError.storageContainerUnavailable
        }
        let component: SplitManager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        add(component: component)
        return component
    }

    func getEndpointFactory(filterBuilder: FilterBuilder) throws -> EndpointFactory {
        if let obj = get(for: EndpointFactory.self) as? EndpointFactory {
            return obj
        }
        splitsFilterQueryString = try filterBuilder.add(filters: splitClientConfig.sync.filters).build()
        let component: EndpointFactory = EndpointFactory(serviceEndpoints: splitClientConfig.serviceEndpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsFilterQueryString)
        add(component: component)
        return component
    }

    func getRestClient(httpClient: HttpClient, reachabilityChecker: HostReachabilityChecker) throws -> RestClient {

        if let obj = get(for: RestClient.self) as? RestClient {
            return obj
        }
        guard let endpointFactory = get(for: EndpointFactory.self) as? EndpointFactory else {
            throw ComponentError.endpointFactoryUnavailable
        }
        let component: RestClient = DefaultRestClient(httpClient: httpClient,
                                                      endpointFactory: endpointFactory,
                                                      reachabilityChecker: reachabilityChecker)
        add(component: component)
        return component
    }
}

enum ComponentError: Error {
    case storageContainerUnavailable
    case endpointFactoryUnavailable
    case unknown
}
