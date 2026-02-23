//  TrackerValidation
//  Copyright © 2022 Split. All rights reserved.

import Foundation

public protocol TrackerEventValidator: Sendable {
    func validate(key: String?, trafficTypeName: String?, eventTypeId: String?, value: Double?, properties: [String: Any]?, isSdkReady: Bool) -> TrackerValidationError?
}

public protocol TrackerPropertyValidator: Sendable {
    func validate(properties: [String: Any]?, initialSizeInBytes: Int, validationTag: String) -> TrackerPropertyResult
}

public protocol TrackerLogger: Sendable {
    func log(errorInfo: TrackerValidationError, tag: String)
    func e(message: String, tag: String)
    func v(_ message: String)
}
