//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

// All events (internal & external) support metadata.
// Internal errors are propagated to the customer as events "(.sdkError)". The error info will travel as the event metadata.
struct SplitInternalEventWithMetadata {
    let type: SplitInternalEvent
    let metadata: EventMetadata?
    
    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
}

@objc public class EventMetadata: NSObject {
    var type: EventMetadataType
    var data: [String] = []
    
    init(type: EventMetadataType, data: [String] = []) {
        self.type = type
        self.data = data
    }
}

enum EventMetadataType: Int {
    case FEATURE_FLAGS_SYNC_ERROR
    case SEGMENTS_SYNC_ERROR
    
    public func toString() -> String {
        switch self {
            case .FEATURE_FLAGS_SYNC_ERROR:
                return "FEATURE_FLAGS_SYNC_ERROR"
            case .SEGMENTS_SYNC_ERROR:
                return "SEGMENTS_SYNC_ERROR"
            
        }
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
