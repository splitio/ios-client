//
//  EventsTracker.swift
//  Split
//
//  Created by Javier Avrudsky on 30-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol EventsTracker: AnyObject {
    var isTrackingEnabled: Bool { get set }
    func track(
        eventType: String,
        trafficType: String?,
        value: Double?,
        properties: [String: Any]?,
        matchingKey: String,
        isSdkReady: Bool) -> Bool
}

class DefaultEventsTracker: EventsTracker {
    private let config: SplitClientConfig
    private let eventValidator: EventValidator
    private let validationLogger: ValidationMessageLogger
    private let propertyValidator: PropertyValidator
    private let telemetryProducer: TelemetryEvaluationProducer?
    private let synchronizer: Synchronizer
    var isTrackingEnabled: Bool = true

    init(
        config: SplitClientConfig,
        synchronizer: Synchronizer,
        eventValidator: EventValidator,
        propertyValidator: PropertyValidator,
        validationLogger: ValidationMessageLogger,
        telemetryProducer: TelemetryEvaluationProducer?) {
        self.config = config
        self.synchronizer = synchronizer
        self.eventValidator = eventValidator
        self.propertyValidator = propertyValidator
        self.validationLogger = validationLogger
        self.telemetryProducer = telemetryProducer
    }

    func track(
        eventType: String,
        trafficType: String? = nil,
        value: Double? = nil,
        properties: [String: Any]?,
        matchingKey: String,
        isSdkReady: Bool) -> Bool {
        if !isTrackingEnabled {
            Logger.v("Event not tracked because tracking is disabled")
            return false
        }

        let timeStart = Stopwatch.now()
        let validationTag = "track"

        guard let trafficType = trafficType ?? config.trafficType else { return false }

        if let errorInfo = eventValidator.validate(
            key: matchingKey,
            trafficTypeName: trafficType,
            eventTypeId: trafficType,
            value: value,
            properties: properties,
            isSdkReady: isSdkReady) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return false
            }
        }

        // Validate properties
        let propertyValidationResult = propertyValidator.validate(
            properties: properties,
            initialSizeInBytes: config.initialEventSizeInBytes,
            validationTag: validationTag)

        if !propertyValidationResult.isValid {
            if let errorMessage = propertyValidationResult.errorMessage {
                validationLogger.e(message: errorMessage, tag: validationTag)
            }
            return false
        }

        let event = EventDTO(trafficType: trafficType, eventType: eventType)
        event.key = matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        event.properties = propertyValidationResult.validatedProperties
        event.sizeInBytes = propertyValidationResult.sizeInBytes
        synchronizer.pushEvent(event: event)
        telemetryProducer?.recordLatency(method: .track, latency: Stopwatch.interval(from: timeStart))

        return true
    }
}
