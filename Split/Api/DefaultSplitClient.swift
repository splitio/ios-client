//
//  DefaultSplitClient.swift
//  Split
//
//  Created by Brian Sztamfater on 20/9/17.
//  Modified by Natalia Stele on 11/10/17.
//
//

import Foundation

typealias DestroyHandler = () -> Void

public final class DefaultSplitClient: NSObject, SplitClient, TelemetrySplitClient {

    private var storageContainer: SplitStorageContainer
    private var key: Key
    private let config: SplitClientConfig
    private var eventsManager: SplitEventsManager
    private let validationLogger: ValidationMessageLogger
    private var treatmentManager: TreatmentManager
    private let anyValueValidator: AnyValueValidator
    private var isClientDestroyed = false
    private let eventsTracker: EventsTracker
    private weak var clientManager: SplitClientManager?

    var initStopwatch: Stopwatch?

    init(config: SplitClientConfig,
         key: Key,
         treatmentManager: TreatmentManager,
         apiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         eventsManager: SplitEventsManager,
         eventsTracker: EventsTracker,
         clientManager: SplitClientManager) {

        self.config = config
        self.key = key
        self.eventsTracker = eventsTracker
        self.validationLogger = DefaultValidationMessageLogger()
        self.eventsManager = eventsManager
        self.storageContainer = storageContainer
        self.treatmentManager = treatmentManager
        self.clientManager = clientManager
        self.anyValueValidator = DefaultAnyValueValidator()

        super.init()

        Logger.i("Split SDK client for key \(key.matchingKey) initialized!")
    }

    deinit {
        DefaultNotificationHelper.instance.removeAllObservers()
    }
}

// MARK: Events
extension DefaultSplitClient {

    public func on(event: SplitEvent, execute action: @escaping SplitAction) {
        on(event: event, runInBackground: false, queue: nil, execute: action)
    }

    public func on(event: SplitEvent, runInBackground: Bool,
                   execute action: @escaping SplitAction) {
        on(event: event, runInBackground: runInBackground, queue: nil, execute: action)
    }

    public func on(event: SplitEvent,
                   queue: DispatchQueue, execute action: @escaping SplitAction) {
        on(event: event, runInBackground: true, queue: queue, execute: action)
    }

    private func on(event: SplitEvent,
                    runInBackground: Bool,
                    queue: DispatchQueue?,
                    execute action: @escaping SplitAction) {

        guard let factory = clientManager?.splitFactory else {
            return
        }

        let task = SplitEventActionTask(action: action, event: event,
                                        runInBackground: runInBackground,
                                        factory: factory,
                                        queue: queue)
        task.event = event
        on(event: event, executeTask: task)
    }
    
    private func on(event: SplitEvent, executeTask task: SplitEventActionTask) {
        if  event != .sdkReadyFromCache, eventsManager.eventAlreadyTriggered(event: event) {
            Logger.w("A handler was added for \(event.toString()) on the SDK, which has already fired and won’t be emitted again. The callback won’t be executed.")
            return
        }
        eventsManager.register(event: event, task: task)
    }
    
    // MARK: Listeners with Metadata
    public func on(event: SplitEvent, executeWithMetadata action: @escaping SplitActionWithMetadata) {
        on(event: event, runInBackground: true, queue: nil, executeWithMetadata: action)
    }
    
    public func on(event: SplitEvent, runInBackground: Bool, executeWithMetadata: @escaping SplitActionWithMetadata) {
        on(event: event, runInBackground: runInBackground, queue: nil, executeWithMetadata: executeWithMetadata)
    }
    
    public func on(event: SplitEvent, runInBackground: Bool, queue: DispatchQueue? = nil, executeWithMetadata action: @escaping SplitActionWithMetadata) {
        on(event: event, runInBackground: runInBackground, queue: queue, action: action)
    }
    
    public func on(event: SplitEvent, queue: DispatchQueue, action: @escaping SplitActionWithMetadata) {
        on(event: event, runInBackground: true, queue: queue, action: action)
    }
    
    private func on(event: SplitEvent, runInBackground: Bool, queue: DispatchQueue? = nil, action: @escaping SplitActionWithMetadata) {
        guard let factory = clientManager?.splitFactory else { return }
        let task = SplitEventActionTask(action: action, event: event, runInBackground: runInBackground, factory: factory, queue: queue)
        on(event: event, executeTask: task)
    }
}

// MARK: Treatment / Evaluation
extension DefaultSplitClient {
    public func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return treatmentManager.getTreatmentWithConfig(split, attributes: nil, evaluationOptions: nil)
    }

    public func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult {
        return treatmentManager.getTreatmentWithConfig(split, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatment(_ split: String) -> String {
        return treatmentManager.getTreatment(split, attributes: nil, evaluationOptions: nil)
    }

    public func getTreatment(_ split: String, attributes: [String: Any]?) -> String {
        return treatmentManager.getTreatment(split, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        return treatmentManager.getTreatments(splits: splits, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfig(splits: splits, attributes: attributes, evaluationOptions: nil)
    }
}

// MARK: Treatment / Evaluation with Properties
extension DefaultSplitClient {
    public func getTreatment(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> String {
        return treatmentManager.getTreatment(split, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return treatmentManager.getTreatments(splits: splits, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> SplitResult {
        return treatmentManager.getTreatmentWithConfig(split, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfig(splits: splits, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return treatmentManager.getTreatmentsByFlagSet(flagSet: flagSet, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return treatmentManager.getTreatmentsByFlagSets(flagSets: flagSets, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentsWithConfigByFlagSet(_ flagSet: String,
                                                 attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfigByFlagSet(flagSet: flagSet, attributes: attributes, evaluationOptions: evaluationOptions)
    }

    public func getTreatmentsWithConfigByFlagSets(_ flagSets: [String],
                                                  attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfigByFlagSets(flagSets: flagSets, attributes: attributes, evaluationOptions: evaluationOptions)
    }
}

// MARK: Track Events
extension DefaultSplitClient {

    public func track(trafficType: String, eventType: String) -> Bool {
        return track(eventType: eventType, trafficType: trafficType, properties: nil)
    }

    public func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return track(eventType: eventType, trafficType: trafficType, value: value, properties: nil)
    }

    public func track(eventType: String) -> Bool {
        return track(eventType: eventType, trafficType: nil, properties: nil)
    }

    public func track(eventType: String, value: Double) -> Bool {
        return track(eventType: eventType, trafficType: nil, value: value, properties: nil)
    }

    public func track(trafficType: String, eventType: String, properties: [String: Any]?) -> Bool {
        return track(eventType: eventType, trafficType: trafficType, properties: properties)
    }

    public func track(trafficType: String, eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return track(eventType: eventType, trafficType: trafficType, value: value, properties: properties)
    }

    public func track(eventType: String, properties: [String: Any]?) -> Bool {
        return track(eventType: eventType, trafficType: nil, properties: properties)
    }

    public func track(eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return track(eventType: eventType, trafficType: nil, value: value, properties: properties)
    }

    func track(eventType: String, trafficType: String? = nil,
               value: Double? = nil, properties: [String: Any]?) -> Bool {
        if isClientDestroyed {
            validationLogger.e(message: "Client has already been destroyed - no calls possible", tag: "track")
            return false
        }
        return eventsTracker.track(eventType: eventType,
                                   trafficType: trafficType,
                                   value: value,
                                   properties: properties,
                                   matchingKey: key.matchingKey,
                                   isSdkReady: eventsManager.eventAlreadyTriggered(event: .sdkReady))
    }
}

// MARK: Persistent attributes feature
extension DefaultSplitClient {

    public func setAttribute(name: String, value: Any) -> Bool {
        if !isValidAttribute(value) {
            logInvalidAttribute(name: name)
            return false
        }
        attributesStorage().set(value: value, name: name, forKey: key.matchingKey)
        return true
    }

    public func getAttribute(name: String) -> Any? {
        attributesStorage().get(name: name, forKey: key.matchingKey)
    }

    public func setAttributes(_ values: [String: Any]) -> Bool {
        for (name, value) in values {
            if !isValidAttribute(value) {
                logInvalidAttribute(name: name)
                return false
            }
        }
        attributesStorage().set(values, forKey: key.matchingKey)
        return true
    }

    public func getAttributes() -> [String: Any]? {
        attributesStorage().getAll(forKey: key.matchingKey)
    }

    public func removeAttribute(name: String) -> Bool {
        attributesStorage().remove(name: name, forKey: key.matchingKey)
        return true
    }

    public func clearAttributes() -> Bool {
        attributesStorage().clear(forKey: key.matchingKey)
        return true
    }

    private func isValidAttribute(_ value: Any) -> Bool {
        return anyValueValidator.isPrimitiveValue(value: value) ||
        anyValueValidator.isList(value: value)
    }

    private func logInvalidAttribute(name: String) {
        Logger.i("Invalid attribute value for evaluation: \(name). " +
                 "Types allowed are String, Number, Boolean and List")
    }

    private func attributesStorage() -> AttributesStorage {
        return storageContainer.attributesStorage
    }
}

// MARK: By Sets evaluation
extension DefaultSplitClient {
    public func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: String] {
        return treatmentManager.getTreatmentsByFlagSet(flagSet: flagSet, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: String] {
        return treatmentManager.getTreatmentsByFlagSets(flagSets: flagSets, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfigByFlagSet(flagSet: flagSet, attributes: attributes, evaluationOptions: nil)
    }

    public func getTreatmentsWithConfigByFlagSets(_ flagSets: [String],
                                                  attributes: [String: Any]?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfigByFlagSets(flagSets: flagSets, attributes: attributes, evaluationOptions: nil)
    }
}

// MARK: Flush / Destroy
extension DefaultSplitClient {

    private func syncFlush() {
        if let clientManager = self.clientManager {
            clientManager.flush()
        }
    }

    public func flush() {
        DispatchQueue.general.async {
            self.syncFlush()
        }
    }

    public func destroy() {
        destroy(completion: nil)
    }

    public func destroy(completion: (() -> Void)?) {
        isClientDestroyed = true
        treatmentManager.destroy()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if let clientManager = self.clientManager {
                clientManager.destroy(forKey: self.key)
                if let completion = completion {
                    completion()
                }
            }
        }
    }
}
