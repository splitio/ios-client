//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

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
}

struct SplitInternalEventWithMetadata: Equatable {
    let type: SplitInternalEvent
    let metadata: [String: Any]?
    
    init(type: SplitInternalEvent, metadata: [String : Any]? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    static func == (lhs: SplitInternalEventWithMetadata, rhs: SplitInternalEventWithMetadata) -> Bool {
        return lhs.type == rhs.type
    }
}
