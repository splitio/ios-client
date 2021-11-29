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

public final class DefaultSplitClient: NSObject, SplitClient, InternalSplitClient {

    var splitsStorage: SplitsStorage? {
        return storageContainer.splitsStorage
    }
    var mySegmentsStorage: MySegmentsStorage? {
        return storageContainer.mySegmentsStorage
    }

    fileprivate var attributesStorage: AttributesStorage {
        return storageContainer.attributesStorage
    }

    private var storageContainer: SplitStorageContainer
    private var key: Key
    private let config: SplitClientConfig

    private var eventsManager: SplitEventsManager
    private var synchronizer: Synchronizer

    private let eventValidator: EventValidator
    private let validationLogger: ValidationMessageLogger
    private var treatmentManager: TreatmentManager!
    private var factoryDestroyHandler: DestroyHandler
    private let anyValueValidator: AnyValueValidator
    private var isClientDestroyed = false

    init(config: SplitClientConfig,
         key: Key,
         apiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         synchronizer: Synchronizer,
         eventsManager: SplitEventsManager,
         destroyHandler: @escaping DestroyHandler) {

        self.config = config
        self.key = key
        self.synchronizer = synchronizer
        self.factoryDestroyHandler = destroyHandler
        self.eventValidator = DefaultEventValidator(splitsStorage: storageContainer.splitsStorage)
        self.validationLogger = DefaultValidationMessageLogger()
        self.eventsManager = eventsManager
        self.storageContainer = storageContainer
        self.anyValueValidator = DefaultAnyValueValidator()

        super.init()

        self.treatmentManager = DefaultTreatmentManager(
            evaluator: DefaultEvaluator(splitClient: self), key: key, splitConfig: config, eventsManager: eventsManager,
            impressionLogger: synchronizer, metricsManager: DefaultMetricsManager.shared,
            attributesStorage: storageContainer.attributesStorage,
            keyValidator: DefaultKeyValidator(),
            splitValidator: DefaultSplitValidator(splitsStorage: storageContainer.splitsStorage),
            validationLogger: validationLogger)

        Logger.i("iOS Split SDK initialized!")
    }

    deinit {
        DefaultNotificationHelper.instance.removeAllObservers()
    }
}

// MARK: Events
extension DefaultSplitClient {
    public func on(event: SplitEvent, execute action: @escaping SplitAction) {
//        if eventsManager.eventAlreadyTriggered(event: event) {
//            Logger.w("A handler was added for \(event.toString()) on the SDK, " +
//                "which has already fired and won’t be emitted again. The callback won’t be executed.")
//            return
//        }
        let task = SplitEventActionTask(action: action)
        eventsManager.register(event: event, task: task)
    }
}

// MARK: Treatment / Evaluation
extension DefaultSplitClient {

    public func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return treatmentManager.getTreatmentWithConfig(split, attributes: nil)
    }

    public func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult {
        return treatmentManager.getTreatmentWithConfig(split, attributes: attributes)
    }

    public func getTreatment(_ split: String) -> String {
        return treatmentManager.getTreatment(split, attributes: nil)
    }

    public func getTreatment(_ split: String, attributes: [String: Any]?) -> String {
        return treatmentManager.getTreatment(split, attributes: attributes)
    }

    public func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        return treatmentManager.getTreatments(splits: splits, attributes: attributes)
    }

    public func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        return treatmentManager.getTreatmentsWithConfig(splits: splits, attributes: attributes)
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

    private func track(eventType: String, trafficType: String? = nil,
                       value: Double? = nil, properties: [String: Any]?) -> Bool {

        let validationTag = "track"

        if isClientDestroyed {
            validationLogger.e(message: "Client has already been destroyed - no calls possible", tag: validationTag)
            return false
        }

        guard let trafficType = trafficType ?? config.trafficType else {
            return false
        }

        if let errorInfo = eventValidator.validate(key: self.key.matchingKey,
                                                   trafficTypeName: trafficType,
                                                   eventTypeId: trafficType,
                                                   value: value,
                                                   properties: properties) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return false
            }
        }

        var validatedProps = properties
        var totalSizeInBytes = config.initialEventSizeInBytes
        if let props = validatedProps {
            let maxBytes = ValidationConfig.default.maximumEventPropertyBytes
            if props.count > ValidationConfig.default.maxEventPropertiesCount {
                validationLogger.w(message: "Event has more than 300 properties. " +
                    "Some of them will be trimmed when processed",
                                   tag: validationTag)
            }

            for (prop, value) in props {
                if !anyValueValidator.isPrimitiveValue(value: value) {
                    validatedProps![prop] = NSNull()
                }

                totalSizeInBytes += estimateSize(for: prop) + estimateSize(for: (value as? String))
                if totalSizeInBytes > maxBytes {
                    validationLogger.e(message: "The maximum size allowed for the properties is 32kb." +
                                                " Current is \(prop). Event not queued", tag: validationTag)
                    return false
                }
            }
        }

        let event = EventDTO(trafficType: trafficType, eventType: eventType)
        event.key = self.key.matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        event.properties = validatedProps
        event.sizeInBytes = totalSizeInBytes
        synchronizer.pushEvent(event: event)

        return true
    }

    private func estimateSize(for value: String?) -> Int {
        if let value = value {
            return MemoryLayout.size(ofValue: value) * value.count
        }
        return 0
    }
}

// MARK: Persistent attributes feature
extension DefaultSplitClient {

    public func setAttribute(name: String, value: Any) -> Bool {
        if !isValidAttribute(value) {
            logInvalidAttribute(name: name)
            return false
        }
        attributesStorage.set(value: value, name: name)
        return true
    }

    public func getAttribute(name: String) -> Any? {
        attributesStorage.get(name: name)
    }

    public func setAttributes(_ values: [String: Any]) -> Bool {
        for (name, value) in values {
            if !isValidAttribute(value) {
                logInvalidAttribute(name: name)
                return false
            }
        }
        attributesStorage.set(values)
        return true
    }

    public func getAttributes() -> [String: Any]? {
        attributesStorage.getAll()
    }

    public func removeAttribute(name: String) -> Bool {
        attributesStorage.remove(name: name)
        return true
    }

    public func clearAttributes() -> Bool {
        attributesStorage.clear()
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
}

// MARK: Flush / Destroy
extension DefaultSplitClient {

    private func syncFlush() {
        self.synchronizer.flush()
        DefaultMetricsManager.shared.flush()
    }

    public func flush() {
        DispatchQueue.global().async {
            self.syncFlush()
        }
    }

    public func destroy() {
        destroy(completion: nil)
    }

    public func destroy(completion: (() -> Void)?) {
        isClientDestroyed = true
        treatmentManager.destroy()
        DispatchQueue.global().async {
            self.syncFlush()
            self.factoryDestroyHandler()
            completion?()
        }
    }
}
