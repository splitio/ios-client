//
//  TestSplitFactory.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class TestSplitFactory {

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    static var sdkVersion: String {
        return "Test_factory"
    }

    var defaultClient: SplitClient?
    var defaultManager: SplitManager?

    var client: SplitClient {
        return defaultClient!
    }

    var manager: SplitManager {
        return defaultManager!
    }

    private let filterBuilder = FilterBuilder()
    var splitDatabase: SplitDatabase
    var reachabilityChecker: HostReachabilityChecker
    var apiKey: String = IntegrationHelper.dummyApiKey
    var userKey: String = IntegrationHelper.dummyUserKey
    var splitConfig: SplitClientConfig = TestingHelper.basicStreamingConfig()
    var httpClient: HttpClient?
    var synchronizer: FullSynchronizer!
    var synchronizerSpy: SynchronizerSpy {
        return synchronizer as! SynchronizerSpy
    }
    var syncManager: SyncManager?

    var version: String {
        return Version.sdk
    }

    init() {
        splitDatabase = TestingHelper.createTestDatabase(name: UUID().uuidString)
        reachabilityChecker = ReachabilityMock()
    }

    func createHttpClient(dispatcher: @escaping HttpClientTestDispatcher,
                      streamingHandler: @escaping TestStreamResponseBindingHandler) {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher,
                                                          streamingHandler: streamingHandler)
        self.httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
    }

    func buildSdk() throws {

        guard let httpClient = self.httpClient else {
            print("HTTP client is null. Fix!!")
            return
        }

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(splitConfig.connectionTimeout)

        let storageContainer = try SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: splitConfig,
            userKey: userKey, databaseName: "dummy", telemetryStorage: nil, testDatabase: splitDatabase)

        let manager = DefaultSplitManager(splitsStorage: storageContainer.splitsStorage)
        defaultManager = manager

        let eventsManager = DefaultSplitEventsManager(config: splitConfig)
        eventsManager.start()

        let splitsFilterQueryString = try filterBuilder.add(filters: splitConfig.sync.filters).build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: splitConfig.serviceEndpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: httpClient,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: reachabilityChecker)

        let apiFacadeBuilder = SplitApiFacade.builder().setUserKey(userKey)
            .setSplitConfig(splitConfig).setRestClient(restClient).setEventsManager(eventsManager)
            .setStorageContainer(storageContainer).setSplitsQueryString(splitsFilterQueryString)

        _ = apiFacadeBuilder.setStreamingHttpClient(httpClient)

        let apiFacade = apiFacadeBuilder.build()

        let impressionsFlushChecker = DefaultRecorderFlushChecker(maxQueueSize: splitConfig.impressionsQueueSize,
                                                                  maxQueueSizeInBytes: splitConfig.impressionsQueueSize)

        let impressionsSyncHelper = ImpressionsRecorderSyncHelper(
            impressionsStorage: storageContainer.impressionsStorage, accumulator: impressionsFlushChecker)

        let eventsFlushChecker
            = DefaultRecorderFlushChecker(maxQueueSize: Int(splitConfig.eventsQueueSize),
                                          maxQueueSizeInBytes: splitConfig.maxEventsQueueMemorySizeInBytes)
        let eventsSyncHelper = EventsRecorderSyncHelper(eventsStorage: storageContainer.eventsStorage,
                                                        accumulator: eventsFlushChecker)

        let syncWorkerFactory = DefaultSyncWorkerFactory(userKey: userKey,
                                                         splitConfig: splitConfig,
                                                         splitsFilterQueryString: splitsFilterQueryString,
                                                         apiFacade: apiFacade,
                                                         storageContainer: storageContainer,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         eventsManager: eventsManager)

        self.synchronizer = SynchronizerSpy(splitConfig: splitConfig, splitApiFacade: apiFacade,
                                            telemetrySynchronizer: nil,
                                            splitStorageContainer: storageContainer,
                                            syncWorkerFactory: syncWorkerFactory,
                                            impressionsSyncHelper: impressionsSyncHelper,
                                            eventsSyncHelper: eventsSyncHelper,
                                            splitsFilterQueryString: splitsFilterQueryString,
                                            splitEventsManager: eventsManager)

        guard let synchronizer = self.synchronizer else {
            return
        }

        let syncManager = SyncManagerBuilder().setUserKey(userKey).setStorageContainer(storageContainer)
            .setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade).setSynchronizer(synchronizer)
            .setSplitConfig(splitConfig).build()

        // Sec api not available for testing
        // Should build a mock here
        //setupBgSync(config: config, apiKey: apiKey, userKey: userKey)

        defaultClient = DefaultSplitClient(config: splitConfig, key: Key(matchingKey: userKey), apiFacade: apiFacade,
                                           storageContainer: storageContainer,
                                           synchronizer: synchronizer, eventsManager: eventsManager) {
            syncManager.stop()
            manager.destroy()
            eventsManager.stop()
        }

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
