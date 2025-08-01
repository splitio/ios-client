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
    case buildFailed(name: String)
}

class SplitComponentFactory {
    /// Build the main HttpClient, wiring proxyConfiguration from SplitClientConfig
    func buildHttpClient() -> HttpClient {
        return DefaultHttpClient(
            configuration: HttpSessionConfig.default,
            proxyConfiguration: splitClientConfig.proxyConfiguration)
    }

    private let kImpressionsFlushCheckerName = "kImpressionsFlushChecker"
    private let kEventsFlushCheckerName = "kEventsFlushChecker"

    private let apiKey: String
    private let userKey: String
    private let splitClientConfig: SplitClientConfig
    private var splitsFilterQueryString = ""
    private var flagsSpec = Spec.flagsSpec
    private var catalog = SplitComponentCatalog()
    private let validationLogger = DefaultValidationMessageLogger()

    init(splitClientConfig: SplitClientConfig, apiKey: String, userKey: String) {
        self.splitClientConfig = splitClientConfig
        self.apiKey = apiKey
        self.userKey = userKey
    }

    func buildStorageContainer(databaseName: String,
                               telemetryStorage: TelemetryStorage?,
                               testDatabase: SplitDatabase?) throws -> SplitStorageContainer {
        let component: SplitStorageContainer =
        try SplitDatabaseHelper.buildStorageContainer(splitClientConfig: splitClientConfig,
                                                      apiKey: apiKey,
                                                      userKey: userKey,
                                                      databaseName: databaseName,
                                                      telemetryStorage: telemetryStorage,
                                                      testDatabase: testDatabase)
        catalog.add(component: component)
        return component
    }

    func getSplitEventsManagerCoordinator() -> SplitEventsManagerCoordinator {
        if let obj = catalog.get(for: SplitEventsManagerCoordinator.self) as? SplitEventsManagerCoordinator {
            return obj
        }
        let component: SplitEventsManagerCoordinator = MainSplitEventsManager()
        catalog.add(component: component)
        return component
    }

    func getSplitManager() throws -> SplitManager {
        if let obj = catalog.get(for: SplitManager.self) as? SplitManager {
            return obj
        }
        let storageContainer = try getSplitStorageContainer()
        let component: SplitManager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        catalog.add(component: component)
        return component
    }

    func getEndpointFactory() throws -> EndpointFactory {
        if let obj = catalog.get(for: EndpointFactory.self) as? EndpointFactory {
            return obj
        }

        let flagSetsValidator = DefaultFlagSetsValidator(
            telemetryProducer: try getSplitStorageContainer().telemetryStorage)
        let filterBuilder = FilterBuilder(flagSetsValidator: flagSetsValidator)
        splitsFilterQueryString = try filterBuilder.add(filters: splitClientConfig.sync.filters).build()
        let component: EndpointFactory = EndpointFactory(serviceEndpoints: splitClientConfig.serviceEndpoints,
                                                         apiKey: apiKey,
                                                         splitsQueryString: splitsFilterQueryString)
        catalog.add(component: component)
        return component
    }

    func buildFeatureFlagsSynchronizer() throws -> FeatureFlagsSynchronizer {

        let syncWorkerFactory = try buildSyncWorkerFactory()
        let storageContainer = try getSplitStorageContainer()

        let component: FeatureFlagsSynchronizer = DefaultFeatureFlagsSynchronizer(
            splitConfig: splitClientConfig,
            storageContainer: storageContainer,
            syncWorkerFactory: syncWorkerFactory,
            broadcasterChannel: try getSyncEventBroadcaster(),
            splitsFilterQueryString: splitsFilterQueryString,
            flagsSpec: flagsSpec,
            splitEventsManager: getSplitEventsManagerCoordinator()) as FeatureFlagsSynchronizer
        catalog.add(component: component)
        return component
    }

    func buildSynchronizer(notificationHelper: NotificationHelper?) throws -> Synchronizer {

        let syncWorkerFactory = try buildSyncWorkerFactory()
        let storageContainer = try getSplitStorageContainer()

        var telemetrySynchronizer: TelemetrySynchronizer?

        if splitClientConfig.isTelemetryEnabled,
           let configRecorderWorker = syncWorkerFactory.createTelemetryConfigRecorderWorker(),
           let statsRecorderWorker = syncWorkerFactory.createTelemetryStatsRecorderWorker(),
           let periodicStatsRecorderWorker = syncWorkerFactory.createPeriodicTelemetryStatsRecorderWorker() {
            telemetrySynchronizer =
            DefaultTelemetrySynchronizer(configRecorderWorker: configRecorderWorker,
                                         statsRecorderWorker: statsRecorderWorker,
                                         periodicStatsRecorderWorker: periodicStatsRecorderWorker)
        }

        var macosNotificationHelper: NotificationHelper?

#if os(macOS)
        macosNotificationHelper = notificationHelper ?? DefaultNotificationHelper.instance
#endif

        let impressionsTracker = try buildImpressionsTracker(notificationHelper: macosNotificationHelper)

        let eventsSynchronizer = DefaultEventsSynchronizer(syncWorkerFactory: syncWorkerFactory,
                                                           eventsSyncHelper: try buildEventsSyncHelper(),
                                                           telemetryProducer: storageContainer.telemetryStorage)

        let component: Synchronizer = DefaultSynchronizer(splitConfig: splitClientConfig,
                                                          defaultUserKey: userKey,
                                                          featureFlagsSynchronizer: try buildFeatureFlagsSynchronizer(),
                                                          telemetrySynchronizer: telemetrySynchronizer,
                                                          byKeyFacade: getByKeyFacade(),
                                                          splitStorageContainer: storageContainer,
                                                          impressionsTracker: impressionsTracker,
                                                          eventsSynchronizer: eventsSynchronizer,
                                                          splitEventsManager: getSplitEventsManagerCoordinator())
        catalog.add(component: component)
        return component
    }

    func getSynchronizer() throws -> Synchronizer {
        if let obj = catalog.get(for: Synchronizer.self) as? Synchronizer {
            return obj
        }
        throw ComponentError.notFound(name: "Synchronizer")
    }

    func buildImpressionsTracker(notificationHelper: NotificationHelper?) throws -> ImpressionsTracker {
        let storageContainer = try getSplitStorageContainer()
        let uniqueKeyTracker = DefaultUniqueKeyTracker(persistentUniqueKeyStorage: storageContainer.uniqueKeyStorage)

        let  component: ImpressionsTracker
        =  DefaultImpressionsTracker(
            splitConfig: splitClientConfig,
            splitApiFacade: try getSplitApiFacade(),
            storageContainer: storageContainer,
            syncWorkerFactory: try buildSyncWorkerFactory(),
            impressionsSyncHelper: try buildImpressionsSyncHelper(),
            uniqueKeyTracker: uniqueKeyTracker,
            notificationHelper: notificationHelper,
            impressionsObserver: DefaultImpressionsObserver(storage: storageContainer.hashedImpressionsStorage))
        catalog.add(component: component)
        return component
    }

    func getByKeyFacade() -> ByKeyFacade {
        if let obj = catalog.get(for: ByKeyFacade.self) as? ByKeyFacade {
            return obj
        }
        let component: ByKeyFacade = DefaultByKeyFacade()
        catalog.add(component: component)
        return component
    }

    func buildSyncManager(notificationHelper: NotificationHelper?) throws -> SyncManager {
        let component = try SyncManagerBuilder()
            .setUserKey(userKey)
            .setByKeyFacade(getByKeyFacade())
            .setStorageContainer(try getSplitStorageContainer())
            .setEndpointFactory(try getEndpointFactory())
            .setSplitApiFacade(try getSplitApiFacade())
            .setSynchronizer(try getSynchronizer())
            .setNotificationHelper(notificationHelper ?? DefaultNotificationHelper.instance)
            .setSyncBroadcaster(try getSyncEventBroadcaster())
            .setSplitConfig(splitClientConfig).build()
        catalog.add(component: component)
        return component
    }

    func getSyncManager() throws -> SyncManager {
        if let obj = catalog.get(for: SyncManager.self) as? SyncManager {
            return obj
        }
        throw ComponentError.notFound(name: "Sync manager")
    }

    func buildUserConsentManager() throws -> UserConsentManager {

        let component = DefaultUserConsentManager(splitConfig: splitClientConfig,
                                                  storageContainer: try getSplitStorageContainer(),
                                                  syncManager: try getSyncManager(),
                                                  eventsTracker: try getEventsTracker(),
                                                  impressionsTracker: try getImpressionsTracker())
        catalog.add(component: component)
        return component
    }

    func getSplitStorageContainer() throws -> SplitStorageContainer {
        if let obj = catalog.get(for: SplitStorageContainer.self) as? SplitStorageContainer {
            return obj
        }
        throw ComponentError.notFound(name: "Split storage container")
    }

    func getSyncEventBroadcaster() throws -> SyncEventBroadcaster {
        if let obj = catalog.get(for: SyncEventBroadcaster.self) as? SyncEventBroadcaster {
            return obj
        }
        let component: SyncEventBroadcaster = DefaultSyncEventBroadcaster()
        catalog.add(component: component)
        return component
    }

    func getSyncWorkerFactory() throws -> SyncWorkerFactory {
        if let obj = catalog.get(for: SyncWorkerFactory.self) as? SyncWorkerFactory {
            return obj
        }
        throw ComponentError.notFound(name: "Sync worker factory")
    }
}

extension SplitComponentFactory {
    func buildRestClient(httpClient: HttpClient,
                         reachabilityChecker: HostReachabilityChecker) throws -> SplitApiRestClient {
        let endpointFactory = try getEndpointFactory()
        let httpClient = httpClient ?? buildHttpClient()
        let component: SplitApiRestClient = DefaultRestClient(httpClient: httpClient,
                                                              endpointFactory: endpointFactory,
                                                              reachabilityChecker: reachabilityChecker)
        catalog.add(component: component)
        return component
    }

    func getImpressionsRecorderFlushChecker() -> RecorderFlushChecker {
        if let obj = catalog.get(byName: kImpressionsFlushCheckerName) as? RecorderFlushChecker {
            return obj
        }
        let component = DefaultRecorderFlushChecker(maxQueueSize: splitClientConfig.impressionsQueueSize,
                                                    maxQueueSizeInBytes: splitClientConfig.impressionsQueueSize)
        catalog.add(name: kImpressionsFlushCheckerName, component: component)
        return component
    }

    func getEventsRecorderFlushChecker() -> RecorderFlushChecker {
        if let obj = catalog.get(byName: kEventsFlushCheckerName) as? RecorderFlushChecker {
            return obj
        }
        let component = DefaultRecorderFlushChecker(
            maxQueueSize: Int(splitClientConfig.eventsQueueSize),
            maxQueueSizeInBytes: splitClientConfig.maxEventsQueueMemorySizeInBytes)
        catalog.add(name: kEventsFlushCheckerName, component: component)
        return component
    }

    func getSplitApiFacade() throws -> SplitApiFacade {
        if let obj = catalog.get(for: SplitApiFacade.self) as? SplitApiFacade {
            return obj
        }
        throw ComponentError.notFound(name: "Split API facade")
    }

    func getImpressionsSyncHelper() throws -> ImpressionsRecorderSyncHelper {
        if let obj = catalog.get(for: ImpressionsRecorderSyncHelper.self) as? ImpressionsRecorderSyncHelper {
            return obj
        }
        throw ComponentError.notFound(name: "Impressions Sync Helper")
    }

    func getEventsSyncHelper() throws -> EventsRecorderSyncHelper {
        if let obj = catalog.get(for: EventsRecorderSyncHelper.self) as? EventsRecorderSyncHelper {
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

        let component: SplitApiFacade = try builder.build()
        catalog.add(component: component)
        return component
    }

    func buildImpressionsSyncHelper() throws -> ImpressionsRecorderSyncHelper {
        let component = ImpressionsRecorderSyncHelper(
            impressionsStorage: try getSplitStorageContainer().impressionsStorage,
            accumulator: getImpressionsRecorderFlushChecker())
        catalog.add(component: component)
        return component
    }

    func buildEventsSyncHelper() throws -> EventsRecorderSyncHelper {
        let component = EventsRecorderSyncHelper(eventsStorage: try getSplitStorageContainer().eventsStorage,
                                                 accumulator: getEventsRecorderFlushChecker())
        catalog.add(component: component)
        return component
    }

    func buildMySegmentsSyncWorkerFactory() throws -> MySegmentsSyncWorkerFactory {
        let storageContainer = try getSplitStorageContainer()
        let component = DefaultMySegmentsSyncWorkerFactory(splitConfig: splitClientConfig,
                                                           mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                           myLargeSegmentsStorage: storageContainer.myLargeSegmentsStorage,
                                                           mySegmentsFetcher: try getSplitApiFacade().mySegmentsFetcher,
                                                           telemetryProducer: storageContainer.telemetryStorage)
        catalog.add(component: component)
        return component
    }

    func buildSyncWorkerFactory() throws -> SyncWorkerFactory {
        let component = DefaultSyncWorkerFactory(
            userKey: userKey,
            splitConfig: splitClientConfig,
            splitsFilterQueryString: splitsFilterQueryString,
            flagsSpec: flagsSpec,
            apiFacade: try getSplitApiFacade(),
            storageContainer: try getSplitStorageContainer(),
            splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: splitClientConfig.bySetsFilter()),
            ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
            eventsManager: getSplitEventsManagerCoordinator())
        catalog.add(component: component)
        return component
    }
}

extension SplitComponentFactory {
    func buildEventsTracker() throws -> EventsTracker {
        let storageContainer = try getSplitStorageContainer()
        let eventsValidator = DefaultEventValidator(splitsStorage: storageContainer.splitsStorage)
        let propertyValidator = getPropertyValidator()
        let component: EventsTracker = DefaultEventsTracker(config: splitClientConfig,
                                                            synchronizer: try getSynchronizer(),
                                                            eventValidator: eventsValidator,
                                                            propertyValidator: propertyValidator,
                                                            validationLogger: validationLogger,
                                                            telemetryProducer: storageContainer.telemetryStorage)
        catalog.add(component: component)
        return component
    }

    func getEventsTracker() throws -> EventsTracker {
        if let obj = catalog.get(for: EventsTracker.self) as? EventsTracker {
            return obj
        }
        return try buildEventsTracker()
    }

    func buildPropertyValidator(validationLogger: ValidationMessageLogger) -> PropertyValidator {
        let anyValueValidator = DefaultAnyValueValidator()
        let component: PropertyValidator = DefaultPropertyValidator(
            anyValueValidator: anyValueValidator,
            validationLogger: validationLogger
        )
        catalog.add(component: component)
        return component
    }

    func getPropertyValidator() -> PropertyValidator {
        if let obj = catalog.get(for: PropertyValidator.self) as? PropertyValidator {
            return obj
        }
        return buildPropertyValidator(validationLogger: validationLogger)
    }

    func getImpressionsTracker() throws -> ImpressionsTracker {
        if let obj = catalog.get(for: ImpressionsTracker.self) as? ImpressionsTracker {
            return obj
        }
        throw ComponentError.notFound(name: "ImpressionsTracker")
    }
}

extension SplitComponentFactory {
    func getRestClient() throws -> SplitApiRestClient {
        if let obj = catalog.get(for: SplitApiRestClient.self) as? SplitApiRestClient {
            return obj
        }
        throw ComponentError.notFound(name: "Rest client")
    }
}

extension SplitComponentFactory {
    func destroy() {
        catalog.clear()
    }
}
