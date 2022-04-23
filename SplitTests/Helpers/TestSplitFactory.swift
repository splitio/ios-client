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

    var defaultManager: SplitManager?

    var client: SplitClient {
        return clientManager!.defaultClient!
    }

    var manager: SplitManager {
        return defaultManager!
    }

    private(set) var clientManager: SplitClientManager?
    private let filterBuilder = FilterBuilder()
    let userKey: String
    private var key: Key!
    var splitDatabase: SplitDatabase
    var reachabilityChecker: HostReachabilityChecker
    var apiKey: String = IntegrationHelper.dummyApiKey

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

    func buildSdk() throws {

        guard let httpClient = self.httpClient else {
            print("HTTP client is null. Fix!!")
            return
        }

        HttpSessionConfig.default.connectionTimeOut = TimeInterval(splitConfig.connectionTimeout)

        let storageContainer = try SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: splitConfig,
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

        let syncWorkerFactory = DefaultSyncWorkerFactory(userKey: key.matchingKey,
                                                         splitConfig: splitConfig,
                                                         splitsFilterQueryString: splitsFilterQueryString,
                                                         apiFacade: apiFacade,
                                                         storageContainer: storageContainer,
                                                         splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                         eventsManager: eventsManager)

        let byKeyFacade = DefaultByKeyFacade()

        self.synchronizer = SynchronizerSpy(splitConfig: splitConfig,
                                            defaultUserKey: key.matchingKey,
                                            telemetrySynchronizer: nil,
                                            byKeyFacade: byKeyFacade,
                                            splitApiFacade: apiFacade,
                                            splitStorageContainer: storageContainer,
                                            syncWorkerFactory: syncWorkerFactory,
                                            impressionsSyncHelper: impressionsSyncHelper,
                                            eventsSyncHelper: eventsSyncHelper,
                                            splitsFilterQueryString: splitsFilterQueryString,
                                            splitEventsManager: eventsManager)

        guard let synchronizer = self.synchronizer else {
            return
        }

        let syncManager = try SyncManagerBuilder()
            .setUserKey(key.matchingKey)
            .setStorageContainer(storageContainer)
            .setEndpointFactory(endpointFactory).setSplitApiFacade(apiFacade).setSynchronizer(synchronizer)
            .setSplitConfig(splitConfig).setByKeyFacade(byKeyFacade).build()

        // Sec api not available for testing
        // Should build a mock here
        //setupBgSync(config: config, apiKey: apiKey, userKey: userKey)

        let mySegmentsSyncWorkerFactory = DefaultMySegmentsSyncWorkerFactory(
            splitConfig: splitConfig,
            mySegmentsStorage: storageContainer.mySegmentsStorage,
            mySegmentsFetcher: apiFacade.mySegmentsFetcher,
            telemetryProducer: storageContainer.telemetryStorage)


        clientManager = DefaultClientManager(config: splitConfig,
                                             key: key,
                                             splitManager: manager,
                                             apiFacade: apiFacade,
                                             byKeyFacade: byKeyFacade,
                                             storageContainer: storageContainer,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsManagerCoordinator: eventsManager,
                                             mySegmentsSyncWorkerFactory: mySegmentsSyncWorkerFactory,
                                             telemetryStopwatch: nil)

    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
    }
}
