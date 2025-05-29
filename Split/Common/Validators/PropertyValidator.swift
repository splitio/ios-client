//
//  PropertyValidator.swift
//  Split
//
//  Created on 2025-03-26.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

protocol PropertyValidator {
    /// Validates properties for events and impressions
    /// - Parameters:
    ///   - properties: Dictionary of properties to validate
    ///   - initialSizeInBytes: Initial size in bytes to consider for total size calculation
    /// - Returns: ValidationResult containing validated properties and validation status
    func validate(
        properties: [String: Any]?,
        initialSizeInBytes: Int,
        validationTag: String) -> PropertyValidationResult
}

struct PropertyValidationResult {
    let isValid: Bool
    let validatedProperties: [String: Any]?
    let sizeInBytes: Int
    let errorMessage: String?

    static func valid(
        properties: [String: Any]?,
        sizeInBytes: Int) -> PropertyValidationResult {
        return PropertyValidationResult(
            isValid: true,
            validatedProperties: properties,
            sizeInBytes: sizeInBytes,
            errorMessage: nil)
    }

    static func invalid(
        message: String,
        sizeInBytes: Int = 0) -> PropertyValidationResult {
        return PropertyValidationResult(
            isValid: false,
            validatedProperties: nil,
            sizeInBytes: sizeInBytes,
            errorMessage: message)
    }
}

class DefaultPropertyValidator: PropertyValidator {
    private let anyValueValidator: AnyValueValidator
    private let validationLogger: ValidationMessageLogger

    init(
        anyValueValidator: AnyValueValidator,
        validationLogger: ValidationMessageLogger) {
        self.anyValueValidator = anyValueValidator
        self.validationLogger = validationLogger
    }

    func validate(
        properties: [String: Any]?,
        initialSizeInBytes: Int,
        validationTag: String) -> PropertyValidationResult {
        var totalSizeInBytes = initialSizeInBytes

        guard let props = properties else {
            return PropertyValidationResult.valid(properties: nil, sizeInBytes: totalSizeInBytes)
        }

        var validatedProps = props

        if props.count > ValidationConfig.default.maxEventPropertiesCount {
            validationLogger.w(
                message: "Properties object has more than 300 properties. " +
                    "Some of them will be trimmed when processed",
                tag: validationTag)
        }

        for (prop, value) in props {
            if !anyValueValidator.isPrimitiveValue(value: value) {
                validatedProps[prop] = NSNull()
            }

            totalSizeInBytes += estimateSize(for: prop) + estimateSize(for: (value as? String))
            if totalSizeInBytes > ValidationConfig.default.maximumEventPropertyBytes {
                let message = "The maximum size allowed for the properties is 32kb." +
                    " Current property is \(prop). Validation failed"
                validationLogger.e(message: message, tag: validationTag)
                return PropertyValidationResult.invalid(message: message, sizeInBytes: totalSizeInBytes)
            }
        }

        return PropertyValidationResult.valid(properties: validatedProps, sizeInBytes: totalSizeInBytes)
    }

    private func estimateSize(for value: String?) -> Int {
        if let value = value {
            return MemoryLayout.size(ofValue: value) * value.count
        }
        return 0
    }
}
