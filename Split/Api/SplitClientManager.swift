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
}

class DefaultClientManager: SplitClientManager {
    private(set) var defaultClient: SplitClient?
    private var clients = SyncDictionary<Key, SplitClient>()

    private var storageContainer: SplitStorageContainer
    private let config: SplitClientConfig
    private let apiFacade: SplitApiFacade

    private var eventsManagerCoordinator: SplitEventsManagerCoordinator
    private var synchronizer: Synchronizer

    private var eventsTracker: EventsTracker
    private let telemetryProducer: TelemetryProducer?
    private let anyValueValidator: AnyValueValidator
    private let validationLogger: ValidationMessageLogger
    private let defaultKey: Key
    private let syncManager: SyncManager
    private let evaluator: Evaluator
    private let telemetryStopwatch: Stopwatch?
    private let splitManager: SplitManager
    private let byKeyRegistry: ByKeyRegistry
    private let mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactory
    private weak var splitFactory: SplitFactory?

    init(config: SplitClientConfig,
         key: Key,
         splitManager: SplitManager,
         apiFacade: SplitApiFacade,
         byKeyFacade: ByKeyFacade,
         storageContainer: SplitStorageContainer,
         syncManager: SyncManager,
         synchronizer: Synchronizer,
         eventsManagerCoordinator: SplitEventsManagerCoordinator,
         mySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactory,
         telemetryStopwatch: Stopwatch?) {

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
        self.anyValueValidator = DefaultAnyValueValidator()
        self.validationLogger = DefaultValidationMessageLogger()
        self.evaluator = DefaultEvaluator(splitsStorage: storageContainer.splitsStorage,
                                          mySegmentsStorage: storageContainer.mySegmentsStorage)
        self.telemetryStopwatch = telemetryStopwatch

        let eventsValidator = DefaultEventValidator(splitsStorage: storageContainer.splitsStorage)
        self.eventsTracker = DefaultEventsTracker(config: config,
                                                  synchronizer: synchronizer,
                                                  eventValidator: eventsValidator,
                                                  anyValueValidator: anyValueValidator,
                                                  validationLogger: validationLogger,
                                                  telemetryProducer: telemetryProducer)

        defaultClient = createClient(forKey: key)

        (defaultClient as? TelemetrySplitClient)?.initStopwatch = telemetryStopwatch
        eventsManagerCoordinator.start()

        defaultClient?.on(event: .sdkReadyFromCache) {
            DispatchQueue.global().async {
                self.telemetryProducer?.recordTimeUntilReadyFromCache(self.telemetryStopwatch?.interval() ?? 0)
            }
        }

        defaultClient?.on(event: .sdkReady) {
            DispatchQueue.global().async {
                self.telemetryProducer?.recordTimeUntilReady(self.telemetryStopwatch?.interval() ?? 0)
                self.synchronizer.synchronizeTelemetryConfig()
            }
        }

        eventsManagerCoordinator.executorResources.client = defaultClient
        syncManager.start()
    }

    func get(forKey key: Key) -> SplitClient {
        if let client = clients.value(forKey: key) {
            return client
        }

        let previousMatchingKeyCount = matchingKeyCount(forKey: key.matchingKey)
        let client = createClient(forKey: key)
        if previousMatchingKeyCount != matchingKeyCount(forKey: key.matchingKey) {
            syncManager.resetStreaming()
        }
        return client
    }

    func flush() {
        synchronizer.flush()
    }

    func destroy(forKey key: Key) {

        if clients.takeValue(forKey: key) != nil,
           shouldRemoveComponents(forKey: key.matchingKey) {
            byKeyRegistry.remove(forKey: key.matchingKey)
        }

        if clients.count == 0 {
            self.syncManager.stop()
            if let stopwatch = self.telemetryStopwatch {
                telemetryProducer?.recordSessionLength(sessionLength: stopwatch.interval())
            }
            (self.splitManager as? Destroyable)?.destroy()

            self.flush()
            self.eventsManagerCoordinator.stop()
            self.storageContainer.splitsStorage.destroy()
        }
    }

    private func createClient(forKey key: Key) -> SplitClient {

        let userKey = key.matchingKey
        let group = getByKeyGroup(userKey: userKey)

        let treatmentManager = buildTreatmentManager(key: key,
                                                     eventsManager: group.eventsManager)

        let client = buildClient(key: key,
                                 treatmentManager: treatmentManager,
                                 eventsManager: group.eventsManager)

        clients.setValue(client, forKey: key)
        group.eventsManager.executorResources.client = client
        eventsManagerCoordinator.add(group.eventsManager, forKey: userKey)

        if shouldStartSyncKey() {
            synchronizer.start(forKey: userKey)
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
            attributesStorage: storageContainer.attributesStorage,
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: DefaultValidationMessageLogger())
    }

    private func getByKeyGroup(userKey: String) -> ByKeyComponentGroup {

        if let group = byKeyRegistry.group(forKey: userKey) {
            return group
        }

        let eventsManager = DefaultSplitEventsManager(config: config)
        let mySegmentsSynchronizer =
        DefaultMySegmentsSynchronizer(userKey: userKey,
                                      splitConfig: config,
                                      mySegmentsStorage: buildMySegmentsStorage(forKey: userKey),
                                      syncWorkerFactory: mySegmentsSyncWorkerFactory,
                                      splitEventsManager: eventsManager)

        let byKeyGroup = ByKeyComponentGroup(eventsManager: eventsManager,
                                             mySegmentsSynchronizer: mySegmentsSynchronizer,
                                             attributesStorage: attributesStorage(forKey: userKey))

        byKeyRegistry.append(byKeyGroup, forKey: userKey)
        return byKeyGroup
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

    private func shouldRemoveComponents(forKey key: String) -> Bool {
        return !Set(clients.all.keys.map { $0.matchingKey }).contains(key)
    }

    private func shouldStartSyncKey() -> Bool {
        return defaultClient != nil
    }

    private func matchingKeyCount(forKey key: String) -> Int {
        return Set(clients.all.keys.map { $0.matchingKey }).count
    }
}
