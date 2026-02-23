//  TrackerModels
//  Copyright © 2022 Split. All rights reserved.

import Foundation

public struct TrackerEvent: @unchecked Sendable {
    public let trafficType: String
    public let eventType: String
    public var key: String?
    public var value: Double?
    public var timestamp: Int64?
    public var properties: [String: Any]?
    public var sizeInBytes: Int

    public init(trafficType: String, eventType: String) {
        self.trafficType = trafficType
        self.eventType = eventType
        self.sizeInBytes = 0
    }
}

public struct TrackerValidationError: Sendable {
    public let isError: Bool
    public let message: String?

    public init(isError: Bool, message: String?) {
        self.isError = isError
        self.message = message
    }
}

public struct TrackerPropertyResult: @unchecked Sendable {
    public let isValid: Bool
    public let validatedProperties: [String: Any]?
    public let sizeInBytes: Int
    public let errorMessage: String?

    public init(isValid: Bool, validatedProperties: [String: Any]?, sizeInBytes: Int, errorMessage: String?) {
        self.isValid = isValid
        self.validatedProperties = validatedProperties
        self.sizeInBytes = sizeInBytes
        self.errorMessage = errorMessage
    }

    public static func valid(properties: [String: Any]?, sizeInBytes: Int) -> TrackerPropertyResult {
        TrackerPropertyResult(isValid: true, validatedProperties: properties, sizeInBytes: sizeInBytes, errorMessage: nil)
    }

    public static func invalid(message: String, sizeInBytes: Int = 0) -> TrackerPropertyResult {
        TrackerPropertyResult(isValid: false, validatedProperties: nil, sizeInBytes: sizeInBytes, errorMessage: message)
    }
}
