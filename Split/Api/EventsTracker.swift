//
//  EventsTracker.swift
//  Split
//
//  Created by Javier Avrudsky on 30-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol EventsTracker {
    func track(eventType: String,
               trafficType: String?,
               value: Double?,
               properties: [String: Any]?,
               matchingKey: String) -> Bool
}

class DefaultEventsTracker: EventsTracker {

    private let config: SplitClientConfig
    private let eventValidator: EventValidator
    private let validationLogger: ValidationMessageLogger
    private let anyValueValidator: AnyValueValidator
    private let telemetryProducer: TelemetryEvaluationProducer?
    private let synchronizer: Synchronizer

    init(config: SplitClientConfig,
         synchronizer: Synchronizer,
         eventValidator: EventValidator,
         anyValueValidator: AnyValueValidator,
         validationLogger: ValidationMessageLogger,
         telemetryProducer: TelemetryEvaluationProducer?) {

        self.config = config
        self.synchronizer = synchronizer
        self.eventValidator = eventValidator
        self.anyValueValidator = anyValueValidator
        self.validationLogger = validationLogger
        self.telemetryProducer = telemetryProducer
    }

    func track(eventType: String, trafficType: String? = nil,
               value: Double? = nil, properties: [String: Any]?,
               matchingKey: String) -> Bool {
        let timeStart = Stopwatch.now()
        let validationTag = "track"

        guard let trafficType = trafficType ?? config.trafficType else {
            return false
        }

        if let errorInfo = eventValidator.validate(key: matchingKey,
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
        event.key = matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        event.properties = validatedProps
        event.sizeInBytes = totalSizeInBytes
        synchronizer.pushEvent(event: event)
        telemetryProducer?.recordLatency(method: .track, latency: Stopwatch.interval(from: timeStart))

        return true
    }

    private func estimateSize(for value: String?) -> Int {
        if let value = value {
            return MemoryLayout.size(ofValue: value) * value.count
        }
        return 0
    }
}
