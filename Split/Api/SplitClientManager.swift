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

    private var eventsManagerCoordinator: SplitEventsManager
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
         eventsManagerCoordinator: SplitEventsManager,
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

        defaultClient = createClient(forKey: key.matchingKey, eventsManager: eventsManagerCoordinator)

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
        synchronizer.start(forKey: key)
        return client
    }

    func flush() {
        synchronizer.flush()
    }

    func destroy(forKey key: String) {

        if clients.takeValue(forKey: key) != nil,
           clients.count == 0 {
            if let stopwatch = self.telemetryStopwatch {
                telemetryProducer?.recordSessionLength(sessionLength: stopwatch.interval())
            }
            (self.splitManager as? Destroyable)?.destroy()
            self.synchronizer.destroy()
            self.flush()
            self.eventsManagerCoordinator.stop()
            self.storageContainer.splitsStorage.destroy()
        }
    }

    private func createClient(forKey key: String, eventsManager: SplitEventsManager? = nil) -> SplitClient {

        let clientEventsManager = eventsManager ?? DefaultSplitEventsManager(config: config)
        let clientKey = Key(matchingKey: key, bucketingKey: defaultKey.bucketingKey)

        let treatmentManager = DefaultTreatmentManager(
            evaluator: evaluator,
            key: clientKey,
            splitConfig: config,
            eventsManager: clientEventsManager,
            impressionLogger: synchronizer, telemetryProducer: storageContainer.telemetryStorage,
            attributesStorage: storageContainer.attributesStorage,
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: DefaultValidationMessageLogger())

        let byKeyMySegmentsStorage = DefaultByKeyMySegmentsStorage(
            mySegmentsStorage: storageContainer.mySegmentsStorage,
            userKey: key)
        let byKeyAttributesStorage = DefaultByKeyAttributesStorage(
            attributesStorage: storageContainer.attributesStorage,
            userKey: key)

        let mySegmentsSynchronizer = DefaultMySegmentsSynchronizer(userKey: key,
                                                                   splitConfig: config,
                                                                   mySegmentsStorage: byKeyMySegmentsStorage,
                                                                   syncWorkerFactory: mySegmentsSyncWorkerFactory,
                                                                   splitEventsManager: clientEventsManager)

        let byKeyGroup = ByKeyComponentGroup(eventsManager: clientEventsManager,
                                             mySegmentsSynchronizer: mySegmentsSynchronizer,
                                             attributesStorage: byKeyAttributesStorage)

        let client = DefaultSplitClient(config: config,
                                        key: clientKey,
                                        treatmentManager: treatmentManager,
                                        apiFacade: apiFacade,
                                        storageContainer: storageContainer,
                                        eventsManager: clientEventsManager,
                                        eventsTracker: eventsTracker,
                                        clientManager: self)

        clients.setValue(client, forKey: key)
        byKeyRegistry.append(byKeyGroup, forKey: key)
        clientEventsManager.executorResources.client = client

        if shouldStartSyncKey() {
            synchronizer.start(forKey: key)
        }
        clientEventsManager.start()

        return client
    }

    func shouldStartSyncKey() -> Bool {
        return defaultClient != nil
    }
}
