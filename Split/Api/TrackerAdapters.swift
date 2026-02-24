//  TrackerAdapters
//  Copyright © 2022 Split. All rights reserved.

import Foundation

#if !COCOAPODS
import Tracker
#endif

final class EventValidatorAdapter: TrackerEventValidator, @unchecked Sendable {
    private let validator: EventValidator

    init(validator: EventValidator) {
        self.validator = validator
    }

    func validate(key: String?,
                  trafficTypeName: String?,
                  eventTypeId: String?,
                  value: Double?,
                  properties: [String: Any]?,
                  isSdkReady: Bool) -> TrackerValidationError? {
        guard let errorInfo = validator.validate(key: key,
                                                  trafficTypeName: trafficTypeName,
                                                  eventTypeId: eventTypeId,
                                                  value: value,
                                                  properties: properties,
                                                  isSdkReady: isSdkReady) else {
            return nil
        }
        return TrackerValidationError(isError: errorInfo.isError, message: errorInfo.errorMessage)
    }
}

final class PropertyValidatorAdapter: TrackerPropertyValidator, @unchecked Sendable {
    private let validator: PropertyValidator

    init(validator: PropertyValidator) {
        self.validator = validator
    }

    func validate(properties: [String: Any]?,
                  initialSizeInBytes: Int,
                  validationTag: String) -> TrackerPropertyResult {
        let result = validator.validate(properties: properties,
                                        initialSizeInBytes: initialSizeInBytes,
                                        validationTag: validationTag)
        return TrackerPropertyResult(isValid: result.isValid,
                                     validatedProperties: result.validatedProperties,
                                     sizeInBytes: result.sizeInBytes,
                                     errorMessage: result.errorMessage)
    }
}

final class TrackerLoggerAdapter: TrackerLogger, @unchecked Sendable {
    private let validationLogger: ValidationMessageLogger

    init(validationLogger: ValidationMessageLogger) {
        self.validationLogger = validationLogger
    }

    func log(errorInfo: TrackerValidationError, tag: String) {
        if errorInfo.isError {
            let sdkError = ValidationErrorInfo(
                error: .some,
                message: errorInfo.message ?? ""
            )
            validationLogger.log(errorInfo: sdkError, tag: tag)
        } else if let message = errorInfo.message {
            let sdkWarning = ValidationErrorInfo(
                warning: .trafficTypeNameHasUppercaseChars,
                message: message
            )
            validationLogger.log(errorInfo: sdkWarning, tag: tag)
        }
    }

    func e(message: String, tag: String) {
        validationLogger.e(message: message, tag: tag)
    }

    func v(_ message: String) {
        Logger.v(message)
    }
}

extension TrackerEvent {
    func toEventDTO() -> EventDTO {
        let dto = EventDTO(trafficType: trafficType, eventType: eventType)
        dto.key = key
        dto.value = value
        dto.timestamp = timestamp
        dto.properties = properties
        dto.sizeInBytes = sizeInBytes
        return dto
    }
}
