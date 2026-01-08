//  Created by Sebastian Arrubia on 4/16/18

import Foundation

// All events (internal & external) support metadata.
// Internal errors are propagated to the customer as events "(.sdkError)".
// The error info will travel as the event metadata.
@objc public enum EventMetadataType: Int, Sendable {
    case errorFeatureFlagsSync
    case errorSegmentsSync
    case errorAuth
    case errorStreaming
    case errorImpressions
    
    public func toString() -> String {
        switch self {
            case .errorFeatureFlagsSync:
                return "ERROR_FEATURE_FLAGS_SYNC"
            case .errorSegmentsSync:
                return "ERROR_SEGMENTS_SYNC"
            case .errorAuth:
                return "ERROR_AUTH"
            case .errorStreaming:
                return "ERROR_STREAMING"
            case .errorImpressions:
                return "ERROR_IMPRESSIONS"
        }
    }
}

@objc public final class EventMetadata: NSObject, Sendable {
    @objc public let type: EventMetadataType
    @objc public let data: [String]
    
    init(type: EventMetadataType, data: [String] = []) {
        self.type = type
        self.data = data
    }
}

struct SplitInternalEventWithMetadata {
    let type: SplitInternalEvent
    let metadata: EventMetadata?
    
    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
}

enum SplitInternalEvent {
    case mySegmentsUpdated
    case myLargeSegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case myLargeSegmentsLoadedFromCache
    case splitsLoadedFromCache
    case attributesLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
    case sdkError
}
