//
//  SplitComponentFactory.swift
//  Split
//
//  Created by Javier Avrudsky on 06-Oct-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum ComponentError: Error {
    case notFound(name: String)
}

class SplitComponentFactory {
    private let kImpressionsFlushCheckerName = "kImpressionsFlushChecker"
    private let kEventsFlushCheckerName = "kEventsFlushChecker"

    private let apiKey: String
    private let userKey: String
    private let splitClientConfig: SplitClientConfig
    private var splitsFilterQueryString = ""

    private var components: [String: Any] = [:]

    init(splitClientConfig: SplitClientConfig, apiKey: String, userKey: String) {
        self.splitClientConfig = splitClientConfig
        self.apiKey = apiKey
        self.userKey = userKey
    }

    private func get<T>(for classType: T) -> Any? {
        let className = String(describing: classType.self)
        // If component exists, return it
        return components[className]
    }

    // This function is implemented using generics
    // because this way type(of: component) returns the original
    // static type.
    // If using Any instead of T we'd get the dynamic type
    private func add<T>(component: T) {
        let className = String(describing: type(of: component))
        components[className] = component
    }

    // These two method is used to maintain more than one reference
    // to an instance of the same object
    private func add<T>(name: String, component: T) {
        components[name] = component
    }

    private func get(byName name: String) -> Any? {
        return components[name]
    }

    func buildStorageContainer(databaseName: String,
                               telemetryStorage: TelemetryStorage?,
                               testDatabase: SplitDatabase?) throws -> SplitStorageContainer {
        let component: SplitStorageContainer =
            try SplitDatabaseHelper.buildStorageContainer(splitClientConfig: splitClientConfig,
                                                          userKey: userKey,
                                                          databaseName: databaseName,
                                                          telemetryStorage: telemetryStorage,
                                                          testDatabase: testDatabase)
        add(component: component)
        return component
    }

    func getSplitEventsManagerCoordinator() -> SplitEventsManagerCoordinator {
        if let obj = get(for: SplitEventsManagerCoordinator.self) as? SplitEventsManagerCoordinator {
            return obj
        }
        let component: SplitEventsManagerCoordinator = MainSplitEventsManager()
        add(component: component)
        return component
    }

    func getSplitManager() throws -> SplitManager {
        if let obj = get(for: SplitManager.self) as? SplitManager {
            return obj
        }
        let storageContainer = try getSplitStorageContainer()
        let component: SplitManager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        add(component: component)
        return component
    }

    func getEndpointFactory() throws -> EndpointFactory {
        if let obj = get(for: EndpointFactory.self) as? EndpointFactory {
            return obj
        }
        let filterBuilder = FilterBuilder()
        splitsFilterQueryString = try filterBuilder.add(filters: splitClientConfig.sync.filters).build()
        let component: EndpointFactory = EndpointFactory(serviceEndpoints: splitClientConfig.serviceEndpoints,
                                                         apiKey: apiKey,
                                                         splitsQueryString: splitsFilterQueryString)
        add(component: component)
        return component
    }

    func buildRestClient(httpClient: HttpClient,
                         reachabilityChecker: HostReachabilityChecker) throws -> SplitApiRestClient {
        let endpointFactory = try getEndpointFactory()
        let component: SplitApiRestClient = DefaultRestClient(httpClient: httpClient,
                                                              endpointFactory: endpointFactory,
                                                              reachabilityChecker: reachabilityChecker)
        add(component: component)
        return component
    }

    func getImpressionsRecorderFlushChecker() -> RecorderFlushChecker {
        if let obj = get(byName: kImpressionsFlushCheckerName) as? RecorderFlushChecker {
            return obj
        }
        let component = DefaultRecorderFlushChecker(maxQueueSize: splitClientConfig.impressionsQueueSize,
                                                    maxQueueSizeInBytes: splitClientConfig.impressionsQueueSize)
        add(name: kImpressionsFlushCheckerName, component: component)
        return component
    }

    func getEventsRecorderFlushChecker() -> RecorderFlushChecker {
        if let obj = get(byName: kEventsFlushCheckerName) as? RecorderFlushChecker {
            return obj
        }
        let component = DefaultRecorderFlushChecker(
            maxQueueSize: Int(splitClientConfig.eventsQueueSize),
            maxQueueSizeInBytes: splitClientConfig.maxEventsQueueMemorySizeInBytes)
        add(name: kEventsFlushCheckerName, component: component)
        return component
    }

    func getSplitApiFacade() throws -> SplitApiFacade {
        if let obj = get(for: SplitApiFacade.self) as? SplitApiFacade {
            return obj
        }
        throw ComponentError.notFound(name: "Split API facade")
    }

    func getImpressionsSyncHelper() throws -> ImpressionsRecorderSyncHelper {
        if let obj = get(for: ImpressionsRecorderSyncHelper.self) as? ImpressionsRecorderSyncHelper {
            return obj
        }
        throw ComponentError.notFound(name: "Impressions Sync Helper")
    }

    func getEventsSyncHelper() throws -> EventsRecorderSyncHelper {
        if let obj = get(for: EventsRecorderSyncHelper.self) as? EventsRecorderSyncHelper {
            return obj
        }
        throw ComponentError.notFound(name: "Events Sync Helper")
    }

    func buildSplitApiFacade(testHttpClient: HttpClient?) throws -> SplitApiFacade {
        let restClient = try getRestClient()
        let storageContainer = try getSplitStorageContainer()
        let builder = SplitApiFacade.builder()
            .setUserKey(userKey)
            .setSplitConfig(splitClientConfig)
            .setRestClient(restClient)
            .setEventsManager(getSplitEventsManagerCoordinator())
            .setStorageContainer(storageContainer)
            .setSplitsQueryString(splitsFilterQueryString)

        if let telemetryStorage = storageContainer.telemetryStorage {
                _ = builder.setTelemetryStorage(telemetryStorage)
        }

        if let httpClient = testHttpClient {
            _ = builder.setStreamingHttpClient(httpClient)
        }

        let component: SplitApiFacade = builder.build()
        add(component: component)
        return component
    }

    func buildImpressionsSyncHelper() throws -> ImpressionsRecorderSyncHelper {
        let component = ImpressionsRecorderSyncHelper(
            impressionsStorage: try getSplitStorageContainer().impressionsStorage,
            accumulator: getImpressionsRecorderFlushChecker())
        add(component: component)
        return component
    }

    func buildEventsSyncHelper() throws -> EventsRecorderSyncHelper {
        let component = EventsRecorderSyncHelper(eventsStorage: try getSplitStorageContainer().eventsStorage,
                                                 accumulator: getEventsRecorderFlushChecker())
        add(component: component)
        return component
    }

    func buildMySegmentsSyncWorkerFactory() throws -> MySegmentsSyncWorkerFactory {
        let storageContainer = try getSplitStorageContainer()
        let component = DefaultMySegmentsSyncWorkerFactory(splitConfig: splitClientConfig,
                                                           mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                           mySegmentsFetcher: try getSplitApiFacade().mySegmentsFetcher,
                                                           telemetryProducer: storageContainer.telemetryStorage)

        add(component: component)
        return component
    }

    func buildSyncWorkerFactory() throws -> SyncWorkerFactory {
        let component = DefaultSyncWorkerFactory(userKey: userKey,
                                                 splitConfig: splitClientConfig,
                                                 splitsFilterQueryString: splitsFilterQueryString,
                                                 apiFacade: try getSplitApiFacade(),
                                                 storageContainer: try getSplitStorageContainer(),
                                                 splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                 eventsManager: getSplitEventsManagerCoordinator())
        add(component: component)
        return component
    }

    func buildSynchronizer() throws -> Synchronizer {

        let syncWorkerFactory = try buildSyncWorkerFactory()
        var telemetrySynchronizer: TelemetrySynchronizer?
        if splitClientConfig.isTelemetryEnabled,
           let configRecorderWorker = syncWorkerFactory.createTelemetryConfigRecorderWorker(),
           let statsRecorderWorker = syncWorkerFactory.createTelemetryStatsRecorderWorker(),
           let periodicStatsRecorderWorker = syncWorkerFactory.createPeriodicTelemetryStatsRecorderWorker() {
            telemetrySynchronizer = DefaultTelemetrySynchronizer(configRecorderWorker: configRecorderWorker,
                                                         statsRecorderWorker: statsRecorderWorker,
                                                         periodicStatsRecorderWorker: periodicStatsRecorderWorker)
        }

        let component: Synchronizer = DefaultSynchronizer(splitConfig: splitClientConfig,
                                                          defaultUserKey: userKey,
                                                          telemetrySynchronizer: telemetrySynchronizer,
                                                          byKeyFacade: getByKeyFacade(),
                                                          splitApiFacade: try getSplitApiFacade(),
                                                          splitStorageContainer: try getSplitStorageContainer(),
                                                          syncWorkerFactory: syncWorkerFactory,
                                                          impressionsSyncHelper: try buildImpressionsSyncHelper(),
                                                          eventsSyncHelper: try buildEventsSyncHelper(),
                                                          splitsFilterQueryString: splitsFilterQueryString,
                                                          splitEventsManager: getSplitEventsManagerCoordinator())
        add(component: component)
        return component
    }

    func getSynchronizer() throws -> Synchronizer {
        if let obj = get(for: Synchronizer.self) as? Synchronizer {
            return obj
        }
        throw ComponentError.notFound(name: "Synchronizer")
    }

    func getByKeyFacade() -> ByKeyFacade {
        if let obj = get(for: ByKeyFacade.self) as? ByKeyFacade {
            return obj
        }
        let component: ByKeyFacade = DefaultByKeyFacade()
        add(component: component)
        return component
    }

    func buildSyncManager(notificationHelper: NotificationHelper?) throws -> SyncManager {
        let component = SyncManagerBuilder()
            .setUserKey(userKey)
            .setStorageContainer(try getSplitStorageContainer())
            .setEndpointFactory(try getEndpointFactory())
            .setSplitApiFacade(try getSplitApiFacade())
            .setSynchronizer(try getSynchronizer())
            .setNotificationHelper(notificationHelper ?? DefaultNotificationHelper.instance)
            .setSplitConfig(splitClientConfig).build()
        add(component: component)
        return component
    }

    func getRestClient() throws -> SplitApiRestClient {
        if let obj = get(for: SplitApiRestClient.self) as? SplitApiRestClient {
            return obj
        }
        throw ComponentError.notFound(name: "Rest client")
    }

    func getSplitStorageContainer() throws -> SplitStorageContainer {
        if let obj = get(for: SplitStorageContainer.self) as? SplitStorageContainer {
            return obj
        }
        throw ComponentError.notFound(name: "Split storage container")
    }

    func getSyncWorkerFactory() throws -> SyncWorkerFactory {
        if let obj = get(for: SyncWorkerFactory.self) as? SyncWorkerFactory {
            return obj
        }
        throw ComponentError.notFound(name: "SyncWorkerFactory")
    }
}
