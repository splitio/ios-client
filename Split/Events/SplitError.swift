//  SplitError
//  Created by Martin Cardozo on 07/05/2025

import Foundation

/// Internally, the errors will be seen and processed as events by the SDK.
/// When there is an error, the SDK will trigger a new event (.sdkError) and will add it to the events queue.
/// Then, it will be passed to the customer through the listener.

@objc public class SplitError: NSObject, Error {
    let type: SplitErrorType
    let underlyingError: Error?
    let metadata: [String: Any]?
    
    init(type: SplitErrorType, underlyingError: Error? = nil, metadata: [String : Any]? = nil) {
        self.type = type
        self.underlyingError = underlyingError
        self.metadata = metadata
    }
}

//MARK: Errors list
@objc public enum SplitErrorType: Int {
    
    // Networking
    case invalidConfiguration = 404
    case invalidSDKKey = 401
    case invalidImpression = 400
    // Synchronization
    case invalidMatchingFunction = 407
    case invalidMatchingFunctionParameter = 408
    case invalidMatchingFunctionResult = 409
    // Storage
    case invalidEvent = 403
    case invalidTreatment = 405
    case invalidSegment = 406
}

//MARK: Errors descriptions
extension SplitErrorType {
    public func toString() -> String {
        switch self {
            case .invalidConfiguration:
                return "INVALID_CONFIGURATION"
            case .invalidSDKKey:
                return "INVALID_SDK_KEY"
            case .invalidImpression:
                return "INVALID_IMPRESSION"
            case .invalidEvent:
                return "INVALID_EVENT"
            case .invalidTreatment:
                return "INVALID_TREATMENT"
            case .invalidSegment:
                return "INVALID_SEGMENT"
            case .invalidMatchingFunction:
                return "INVALID_MATCHING_FUNCTION"
            case .invalidMatchingFunctionParameter:
                return "INVALID_MATCHING_FUNCTION_PARAMETER"
            case .invalidMatchingFunctionResult:
                return "INVALID_MATCHING_FUNCTION_RESULT"
        }
    }
    
    public func detailedDescription() -> String {
        switch self {
            case .invalidConfiguration:
                return "Details - INVALID_CONFIGURATION"
            case .invalidSDKKey:
                return "Details - INVALID_SDK_KEY"
            case .invalidImpression:
                return "Details - INVALID_IMPRESSION"
            case .invalidEvent:
                return "Details - INVALID_EVENT"
            case .invalidTreatment:
                return "Details - INVALID_TREATMENT"
            case .invalidSegment:
                return "Details - INVALID_SEGMENT"
            case .invalidMatchingFunction:
                return "Details - INVALID_MATCHING_FUNCTION"
            case .invalidMatchingFunctionParameter:
                return "Details - INVALID_MATCHING_FUNCTION_PARAMETER"
            case .invalidMatchingFunctionResult:
                return "Details - INVALID_MATCHING_FUNCTION_RESULT"
        }
    }
}
