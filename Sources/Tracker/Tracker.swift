//  Tracker
//  Created by Javier Avrudsky on 30-Mar-2022.

import Foundation

public protocol Tracker: AnyObject, Sendable {
    var isTrackingEnabled: Bool { get set }
    
    func track(eventType: String, trafficType: String?, value: Double?, properties: [String: Any]?, matchingKey: String, isSdkReady: Bool) -> Bool
}

public final class DefaultTracker: Tracker, @unchecked Sendable {

    private let defaultTrafficType: String?
    private let initialEventSizeInBytes: Int
    private let eventValidator: TrackerEventValidator
    private let propertyValidator: TrackerPropertyValidator
    private let logger: TrackerLogger
    private let onEventPush: (TrackerEvent) -> Void
    private let onTrackLatency: ((Int64) -> Void)?

    public var isTrackingEnabled: Bool = true

    public init(defaultTrafficType: String?, initialEventSizeInBytes: Int, eventValidator: TrackerEventValidator, propertyValidator: TrackerPropertyValidator, logger: TrackerLogger, onEventPush: @escaping (TrackerEvent) -> Void, onTrackLatency: ((Int64) -> Void)? = nil) {

        self.defaultTrafficType = defaultTrafficType
        self.initialEventSizeInBytes = initialEventSizeInBytes
        self.eventValidator = eventValidator
        self.propertyValidator = propertyValidator
        self.logger = logger
        self.onEventPush = onEventPush
        self.onTrackLatency = onTrackLatency
    }

    public func track(eventType: String, trafficType: String? = nil, value: Double? = nil, properties: [String: Any]?, matchingKey: String, isSdkReady: Bool) -> Bool {

        if !isTrackingEnabled {
            logger.v("Event not tracked because tracking is disabled")
            return false
        }

        let timeStart = currentTimeMillis()
        let validationTag = "track"

        guard let trafficType = trafficType ?? defaultTrafficType else { return false }

        if let errorInfo = eventValidator.validate(key: matchingKey, trafficTypeName: trafficType, eventTypeId: trafficType, value: value, properties: properties, isSdkReady: isSdkReady) {
            logger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return false
            }
        }

        let propertyValidationResult = propertyValidator.validate(properties: properties, initialSizeInBytes: initialEventSizeInBytes, validationTag: validationTag)

        if !propertyValidationResult.isValid {
            if let errorMessage = propertyValidationResult.errorMessage {
                logger.e(message: errorMessage, tag: validationTag)
            }
            return false
        }

        var event = TrackerEvent(trafficType: trafficType, eventType: eventType)
        event.key = matchingKey
        event.value = value
        event.timestamp = currentTimeMillis()
        event.properties = propertyValidationResult.validatedProperties
        event.sizeInBytes = propertyValidationResult.sizeInBytes

        onEventPush(event)

        let elapsed = currentTimeMillis() - timeStart
        onTrackLatency?(elapsed)

        return true
    }

    private func currentTimeMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
