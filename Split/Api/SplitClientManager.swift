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
    func get(forKey key: String) -> SplitClient
    func flush()
    func destroy(forKey key: String)
}

class DefaultClientManager: SplitClientManager {
    private(set) var defaultClient: SplitClient?
    private var clients = SyncDictionary<String, SplitClient>()

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

        defaultClient = createClient(forKey: key.matchingKey)

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

    func get(forKey key: String) -> SplitClient {
        if let client = clients.value(forKey: key) {
            return client
        }

        let client = createClient(forKey: key)
        if byKeyRegistry.keys.count > 0 {
            syncManager.resetStreaming()
        }

        return client
    }

    func flush() {
        synchronizer.flush()
    }

    func destroy(forKey key: String) {

        if clients.takeValue(forKey: key) != nil {
            byKeyRegistry.remove(forKey: key)
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

    private func createClient(forKey key: String) -> SplitClient {
        let clientEventsManager = DefaultSplitEventsManager(config: config)
        let clientKey = Key(matchingKey: key, bucketingKey: defaultKey.bucketingKey)

        let treatmentManager = buildTreatmentManager(key: clientKey,
                                                     eventsManager: clientEventsManager)

        let client = buildClient(key: clientKey,
                                 treatmentManager: treatmentManager,
                                 eventsManager: clientEventsManager)

        clients.setValue(client, forKey: key)
        addToByKeyRegistry(userKey: key,
                           eventsManager: clientEventsManager)
        clientEventsManager.executorResources.client = client
        eventsManagerCoordinator.add(clientEventsManager, forKey: key)

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
            attributesStorage: storageContainer.attributesStorage,
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: DefaultValidationMessageLogger())
    }

    private func addToByKeyRegistry(userKey: String,
                                    eventsManager: SplitEventsManager) {

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

    func shouldStartSyncKey() -> Bool {
        return defaultClient != nil
    }
}
