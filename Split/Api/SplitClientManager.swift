//
//  SplitClientManager.swift
//  Split
//
//  Created by Javier Avrudsky on 30-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol SplitClientManager: AnyObject {
    var defaultClient: SplitClient? { get }
    func get(forKey key: Key) -> SplitClient
    func flush()
    func destroy(forKey key: Key)
    var splitFactory: SplitFactory? { get }
}

class DefaultClientManager: SplitClientManager {
    private(set) var defaultClient: SplitClient?

    private var storageContainer: SplitStorageContainer
    private let config: SplitClientConfig
    private let apiFacade: SplitApiFacade

    private var eventsManagerCoordinator: SplitEventsManagerCoordinator
    private var synchronizer: Synchronizer

    private var eventsTracker: EventsTracker
    private let telemetryProducer: TelemetryProducer?
    private let defaultKey: Key
    private let syncManager: SyncManager
    private let evaluator: Evaluator
    private let telemetryStopwatch: Stopwatch?
    private let splitManager: SplitManager
    private let byKeyRegistry: ByKeyRegistry
    private let mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactory
    weak var splitFactory: SplitFactory?

    init(config: SplitClientConfig,
         key: Key,
         splitManager: SplitManager,
         apiFacade: SplitApiFacade,
         byKeyFacade: ByKeyFacade,
         storageContainer: SplitStorageContainer,
         syncManager: SyncManager,
         synchronizer: Synchronizer,
         eventsTracker: EventsTracker,
         eventsManagerCoordinator: SplitEventsManagerCoordinator,
         mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactory,
         telemetryStopwatch: Stopwatch?,
         factory: SplitFactory) {

        self.defaultKey = key
        self.apiFacade = apiFacade
        self.byKeyRegistry = byKeyFacade
        self.config = config
        self.splitManager = splitManager
        self.syncManager = syncManager
        self.mySegmentsSyncWorkerFactory = mySegmentsSyncWorkerFactory
        self.synchronizer = synchronizer
        self.eventsManagerCoordinator = eventsManagerCoordinator
        self.storageContainer = storageContainer
        self.telemetryProducer = storageContainer.telemetryStorage
        self.evaluator = DefaultEvaluator(splitsStorage: storageContainer.splitsStorage,
                                          mySegmentsStorage: storageContainer.mySegmentsStorage)

        self.telemetryStopwatch = telemetryStopwatch

        self.eventsTracker = eventsTracker
        self.splitFactory = factory

        defaultClient = createClient(forKey: key)

        (defaultClient as? TelemetrySplitClient)?.initStopwatch = telemetryStopwatch
        eventsManagerCoordinator.start()

        if let producer = telemetryProducer {
            defaultClient?.on(event: .sdkReadyFromCache) {
                DispatchQueue.general.async { [weak self] in
                    if let self = self {
                        producer.recordTimeUntilReadyFromCache(self.telemetryStopwatch?.interval() ?? 0)
                    }
                }
            }

            defaultClient?.on(event: .sdkReady) {
                DispatchQueue.general.async { [weak self] in
                    if let self = self {
                        producer.recordTimeUntilReady(self.telemetryStopwatch?.interval() ?? 0)
                        self.synchronizer.synchronizeTelemetryConfig()
                    }
                }
            }
        }

        syncManager.start()
    }

    func get(forKey key: Key) -> SplitClient {
        if let client = byKeyRegistry.group(forKey: key)?.splitClient {
            return client
        }

        let shouldResetStreaming = !byKeyRegistry.matchingKeys.contains(key.matchingKey)
        let client = createClient(forKey: key)
        if shouldResetStreaming {
            syncManager.resetStreaming()
        }
        return client
    }

    func flush() {
        synchronizer.flush()
    }

    func destroy(forKey key: Key) {
        if let count = byKeyRegistry.removeAndCount(forKey: key),
            count == 0 {
            self.syncManager.stop()
            if let stopwatch = self.telemetryStopwatch {
                telemetryProducer?.recordSessionLength(sessionLength: stopwatch.interval())
            }
            (self.splitManager as? Destroyable)?.destroy()

            self.flush()
            self.eventsManagerCoordinator.stop()
            self.storageContainer.splitsStorage.destroy()
            Logger.i("Split SDK destroyed")
        }
    }

    private func createClient(forKey key: Key) -> SplitClient {

        let eventsManager = DefaultSplitEventsManager(config: config)
        let treatmentManager = buildTreatmentManager(key: key,
                                                     eventsManager: eventsManager)

        let client = buildClient(key: key,
                                 treatmentManager: treatmentManager,
                                 eventsManager: eventsManager)

        addToByKeyRegistry(key: key,
                           client: client,
                           eventsManager: eventsManager)
        eventsManagerCoordinator.add(eventsManager, forKey: key)

        if shouldStartSyncKey() {
            synchronizer.start(forKey: key)
        }

        return client
    }

    private func buildTreatmentManager(key: Key,
                                       eventsManager: SplitEventsManager) -> TreatmentManager {
        return DefaultTreatmentManager(
            evaluator: evaluator,
            key: key,
            splitConfig: config,
            eventsManager: eventsManager,
            impressionLogger: synchronizer, telemetryProducer: storageContainer.telemetryStorage,
            storageContainer: storageContainer,
            flagSetsValidator: DefaultFlagSetsValidator(telemetryProducer: storageContainer.telemetryStorage),
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: DefaultValidationMessageLogger())
    }

    private func addToByKeyRegistry(key: Key,
                                    client: SplitClient,
                                    eventsManager: SplitEventsManager) {

        let matchingKey = key.matchingKey
        let mySegmentsSynchronizer =
        DefaultMySegmentsSynchronizer(userKey: matchingKey,
                                      splitConfig: config,
                                      mySegmentsStorage: buildMySegmentsStorage(forKey: matchingKey),
                                      syncWorkerFactory: mySegmentsSyncWorkerFactory,
                                      splitEventsManager: eventsManager)

        let byKeyGroup = ByKeyComponentGroup(splitClient: client,
                                             eventsManager: eventsManager,
                                             mySegmentsSynchronizer: mySegmentsSynchronizer,
                                             attributesStorage: attributesStorage(forKey: matchingKey))

        byKeyRegistry.append(byKeyGroup, forKey: key)
    }

    private func buildMySegmentsStorage(forKey key: String) -> ByKeyMySegmentsStorage {
        return DefaultByKeyMySegmentsStorage(
            mySegmentsStorage: storageContainer.mySegmentsStorage,
            userKey: key)
    }

    private func attributesStorage(forKey key: String) -> ByKeyAttributesStorage {
        return DefaultByKeyAttributesStorage(
            attributesStorage: storageContainer.attributesStorage,
            userKey: key)
    }

    private func buildClient(key: Key,
                             treatmentManager: TreatmentManager,
                             eventsManager: SplitEventsManager) -> SplitClient {
        return DefaultSplitClient(config: config,
                                  key: key,
                                  treatmentManager: treatmentManager,
                                  apiFacade: apiFacade,
                                  storageContainer: storageContainer,
                                  eventsManager: eventsManager,
                                  eventsTracker: eventsTracker,
                                  clientManager: self)
    }

    private func shouldStartSyncKey() -> Bool {
        return defaultClient != nil
    }
}
