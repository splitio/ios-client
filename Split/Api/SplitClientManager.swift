//
//  SplitClientManager.swift
//  Split
//
//  Created by Javier Avrudsky on 30-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol SplitClientManager: AnyObject {
    func get(forKey key: String) -> SplitClient
    func flush()
    func destroy(forKey key: String)
}

class DefaultClientManager: SplitClientManager {
    private let defaultClient: SplitClient?
    private var clients = ConcurrentDictionary<String, SplitClient>()

    private var storageContainer: SplitStorageContainer
    private let config: SplitClientConfig
    private let apiFacade: SplitApiFacade

    private var eventsManager: SplitEventsManager
    private var synchronizer: Synchronizer

    private var factoryDestroyHandler: DestroyHandler
    private var eventsTracker: EventsTracker
    private let telemetryProducer: TelemetryProducer?
    private let anyValueValidator: AnyValueValidator
    private let validationLogger: ValidationMessageLogger
    private let defaultKey: Key
    private let evaluator: Evaluator
    private let telemetryStopwatch: Stopwatch?
    private weak var splitFactory: SplitFactory?


    var initStopwatch: Stopwatch?

    init(config: SplitClientConfig,
         key: Key,
         apiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         synchronizer: Synchronizer,
         eventsManager: SplitEventsManagerCoordinator,
         telemetryStopwatch: Stopwatch?) {

        self.defaultKey = key
        self.apiFacade = apiFacade
        self.config = config
        self.synchronizer = synchronizer
        self.eventsManager = eventsManager
        self.storageContainer = storageContainer
        self.telemetryProducer = storageContainer.telemetryStorage
        self.anyValueValidator = DefaultAnyValueValidator()
        self.validationLogger = DefaultValidationMessageLogger()
        self.evaluator = DefaultEvaluator(storageContainer: storageContainer)
        self.telemetryStopwatch = telemetryStopwatch

        let eventsValidator = DefaultEventValidator(splitsStorage: storageContainer.splitsStorage)
        self.eventsTracker = DefaultEventsTracker(config: config,
                                                  synchronizer: synchronizer,
                                                  eventValidator: eventsValidator,
                                                  anyValueValidator: anyValueValidator,
                                                  validationLogger: validationLogger,
                                                  telemetryProducer: telemetryProducer)
    }


    func get(forKey key: String) -> SplitClient {

    }

    func flush() {
        synchronizer.flush()
    }

    func destroy(forKey key: String) {

        let client = clients.takeValue(forKey: key)
        synchronizer.
        if clients.count == 0 {
            if let stopwatch = self.telemetryStopwatch {
                telemetryProducer?.recordSessionLength(sessionLength: stopwatch.interval())
            }
            DispatchQueue.global().async {
                self.flush()
                self.factoryDestroyHandler()
                //            completion?()
            }
        }
    }

    private func createClient(forKey key: String) {

        let eventsManager = DefaultSplitEventsManager(config: config)
        let clientKey = Key(matchingKey: key, bucketingKey: defaultKey.bucketingKey)

        let treatmentManager = DefaultTreatmentManager(
            evaluator: evaluator,
            key: clientKey,
            splitConfig: config,
            eventsManager: eventsManager,
            impressionLogger: synchronizer, telemetryProducer: storageContainer.telemetryStorage,
            attributesStorage: storageContainer.attributesStorage,
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: DefaultValidationMessageLogger())

        let client = DefaultSplitClient(config: config,
                                        key: clientKey,
                                        treatmentManager: treatmentManager,
                                        apiFacade: apiFacade,
                                        storageContainer: storageContainer,
                                        eventsManager: eventsManager,
                                        eventsTracker: eventsTracker)

        (defaultClient as? TelemetrySplitClient)?.initStopwatch = params.initStopwatch
        eventsManager.start()

        defaultClient?.on(event: .sdkReadyFromCache) {
            DispatchQueue.global().async {
                self.telemetryProducer?.recordTimeUntilReadyFromCache(params.initStopwatch.interval())
            }
        }

        defaultClient?.on(event: .sdkReady) {
            DispatchQueue.global().async {
                self.telemetryProducer?.recordTimeUntilReady(params.initStopwatch.interval())
                synchronizer.synchronizeTelemetryConfig()
            }
        }

        eventsManager.executorResources.client = defaultClient
    }
}



// factory destroy
//{ [weak self] in
//    syncManager.stop()
//    if let self = self, let manager = self.defaultManager as? Destroyable {
//        manager.destroy()
//    }
//    eventsManager.stop()
//    storageContainer.oneKeyMySegmentsStorage.destroy()
//    storageContainer.splitsStorage.destroy()
//}
