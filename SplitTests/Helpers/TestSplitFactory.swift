//
//  TestSplitFactory.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class TestSplitFactory: SplitFactory {

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    static var sdkVersion: String {
        return "Test_factory"
    }

    var defaultManager: SplitManager?

    var client: SplitClient {
        return clientManager!.defaultClient!
    }

    var manager: SplitManager {
        return defaultManager!
    }

    var userConsent: UserConsent {
        userConsentManager?.getStatus() ?? .granted
    }

    private(set) var clientManager: SplitClientManager?
    private let filterBuilder = FilterBuilder(flagSetsValidator: DefaultFlagSetsValidator(telemetryProducer: nil))
    let userKey: String
    private var key: Key!
    var splitDatabase: SplitDatabase
    var reachabilityChecker: HostReachabilityChecker
    var apiKey: String = IntegrationHelper.dummyApiKey
    private(set) var userConsentManager: UserConsentManager?

    var splitConfig: SplitClientConfig = TestingHelper.basicStreamingConfig()
    var httpClient: HttpClient?
    var synchronizer: Synchronizer!
    var synchronizerSpy: SynchronizerSpy {
        return synchronizer as! SynchronizerSpy
    }
    var syncManager: SyncManager?

    var version: String {
        return Version.sdk
    }

    init(userKey: String) {
        self.userKey = userKey
        splitDatabase = TestingHelper.createTestDatabase(name: UUID().uuidString)
        reachabilityChecker = ReachabilityMock()
    }

    func createHttpClient(dispatcher: @escaping HttpClientTestDispatcher,
                      streamingHandler: @escaping TestStreamResponseBindingHandler) {
        key = Key(matchingKey: userKey)
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher,
                                                          streamingHandler: streamingHandler)
        self.httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func buildSdk(polling: Bool = false) throws {

        guard let httpClient = self.httpClient else {
            print("HTTP client is null. Fix!!")
            return
        }

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(splitConfig.connectionTimeout)

        let storageContainer = try SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: splitConfig, apiKey: IntegrationHelper.dummyApiKey,
            userKey: key.matchingKey, databaseName: "dummy", telemetryStorage: nil, testDatabase: splitDatabase)

        let manager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        defaultManager = manager

        let eventsManager = MainSplitEventsManager()
        eventsManager.start()

        let splitsFilterQueryString = try filterBuilder.add(filters: splitConfig.sync.filters).build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: splitConfig.serviceEndpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: httpClient,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: reachabilityChecker)

        let apiFacadeBuilder = SplitApiFacade.builder().setUserKey(key.matchingKey)
            .setSplitConfig(splitConfig).setRestClient(restClient).setEventsManager(eventsManager)
            .setStorageContainer(storageContainer).setSplitsQueryString(splitsFilterQueryString)

        _ = apiFacadeBuilder.setStreamingHttpClient(httpClient)

        let apiFacade = try! apiFacadeBuilder.build()

        let impressionsFlushChecker = DefaultRecorderFlushChecker(maxQueueSize: splitConfig.impressionsQueueSize,
                                                                  maxQueueSizeInBytes: splitConfig.impressionsQueueSize)

        let impressionsSyncHelper = ImpressionsRecorderSyncHelper(
            impressionsStorage: storageContainer.impressionsStorage, accumulator: impressionsFlushChecker)

        let eventsFlushChecker
            = DefaultRecorderFlushChecker(maxQueueSize: Int(splitConfig.eventsQueueSize),
                                          maxQueueSizeInBytes: splitConfig.maxEventsQueueMemorySizeInBytes)
        let eventsSyncHelper = EventsRecorderSyncHelper(eventsStorage: storageContainer.eventsStorage,
                                                        accumulator: eventsFlushChecker)

        let syncWorkerFactory = DefaultSyncWorkerFactory(userKey: key.matchingKey,
                                                         splitConfig: splitConfig,
                                                         splitsFilterQueryString: splitsFilterQueryString,
                                                         flagsSpec: "1.1",
                                                         apiFacade: apiFacade,
                                                         storageContainer: storageContainer,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: nil),
                                                         ruleBasedSegmentChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
                                                         eventsManager: eventsManager)

        let impressionsTracker = DefaultImpressionsTracker(splitConfig: splitConfig,
                                                           splitApiFacade: apiFacade,
                                                           storageContainer: storageContainer,
                                                           syncWorkerFactory: syncWorkerFactory,
                                                           impressionsSyncHelper: impressionsSyncHelper,
                                                           uniqueKeyTracker: nil,
                                                           notificationHelper: nil,
                                                           impressionsObserver: DefaultImpressionsObserver(storage: storageContainer.hashedImpressionsStorage))

        let eventsSynchronizer = DefaultEventsSynchronizer(syncWorkerFactory: syncWorkerFactory,
                                                           eventsSyncHelper: eventsSyncHelper,
                                                           telemetryProducer: storageContainer.telemetryStorage)

        let byKeyFacade = DefaultByKeyFacade()
        let broadcasterChannel = DefaultSyncEventBroadcaster()

        let fFlagsSynchronizer = DefaultFeatureFlagsSynchronizer(splitConfig: splitConfig,
                                                                 storageContainer: storageContainer,
                                                                 syncWorkerFactory: syncWorkerFactory,
                                                                 broadcasterChannel: broadcasterChannel,
                                                                 splitsFilterQueryString: splitsFilterQueryString,
                                                                 flagsSpec: "1.1",
                                                                 splitEventsManager: eventsManager)

        self.synchronizer = SynchronizerSpy(splitConfig: splitConfig,
                                            defaultUserKey: key.matchingKey,
                                            featureFlagsSynchronizer: fFlagsSynchronizer,
                                            telemetrySynchronizer: nil,
                                            byKeyFacade: byKeyFacade,
                                            splitStorageContainer: storageContainer,
                                            impressionsTracker: impressionsTracker,
                                            eventsSynchronizer: eventsSynchronizer,
                                            splitEventsManager: eventsManager)

        guard let synchronizer = self.synchronizer else {
            return
        }

        let syncManager = try SyncManagerBuilder()
            .setUserKey(key.matchingKey)
            .setStorageContainer(storageContainer)
            .setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade).setSynchronizer(synchronizer)
            .setSplitConfig(splitConfig)
            .setSyncBroadcaster(broadcasterChannel)
            .setByKeyFacade(byKeyFacade).build()

        // Sec api not available for testing
        // Should build a mock here
        //setupBgSync(config: config, apiKey: apiKey, userKey: userKey)

        let mySegmentsSyncWorkerFactory = DefaultMySegmentsSyncWorkerFactory(
            splitConfig: splitConfig,
            mySegmentsStorage: storageContainer.mySegmentsStorage,
            myLargeSegmentsStorage: storageContainer.myLargeSegmentsStorage,
            mySegmentsFetcher: apiFacade.mySegmentsFetcher,
            telemetryProducer: storageContainer.telemetryStorage)

        let logger = DefaultValidationMessageLogger()
        let propertyValidator = DefaultPropertyValidator(anyValueValidator: DefaultAnyValueValidator(), validationLogger: logger)
        let eventsTracker = DefaultEventsTracker(config: splitConfig,
                                                 synchronizer: synchronizer,
                                                 eventValidator: DefaultEventValidator(splitsStorage: storageContainer.splitsStorage),
                                                 propertyValidator: propertyValidator,
                                                 validationLogger: logger,
                                                 telemetryProducer: storageContainer.telemetryStorage)

        userConsentManager = DefaultUserConsentManager(splitConfig: splitConfig,
                                                       storageContainer: storageContainer,
                                                       syncManager: syncManager,
                                                       eventsTracker: eventsTracker,
                                                       impressionsTracker: impressionsTracker)
        let rolloutCacheManager = DefaultRolloutCacheManager(generalInfoStorage: storageContainer.generalInfoStorage,
                                                             rolloutCacheConfiguration: splitConfig.rolloutCacheConfiguration ?? RolloutCacheConfiguration.builder().build(),
                                                             storages: storageContainer.splitsStorage, storageContainer.mySegmentsStorage, storageContainer.myLargeSegmentsStorage)

        if polling { splitConfig.streamingEnabled = false }
        
        clientManager = DefaultClientManager(config: splitConfig,
                                             key: key,
                                             splitManager: manager,
                                             apiFacade: apiFacade,
                                             byKeyFacade: byKeyFacade,
                                             storageContainer: storageContainer,
                                             rolloutCacheManager: rolloutCacheManager,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsTracker: eventsTracker,
                                             eventsManagerCoordinator: eventsManager,
                                             mySegmentsSyncWorkerFactory: mySegmentsSyncWorkerFactory,
                                             telemetryStopwatch: nil,
                                             propertyValidator: propertyValidator,
                                             factory: self)
    }

    func client(matchingKey: String) -> SplitClient {
        return clientManager!.get(forKey: Key(matchingKey: matchingKey))
    }

    func client(matchingKey: String, bucketingKey: String?) -> SplitClient {
        return clientManager!.get(forKey: Key(matchingKey: matchingKey, bucketingKey: bucketingKey))
    }

    func client(key: Key) -> SplitClient {
        return clientManager!.get(forKey:key)
    }

    func setUserConsent(enabled: Bool) {
        userConsentManager?.set(enabled ? .granted : .declined)
    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: config.prefix, sdkKey: apiKey)
#if os(iOS) || os(tvOS)
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(dbKey: dbKey, prefix: config.prefix, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(dbKey: dbKey, userKey: userKey)
        }
#endif
    }
}
