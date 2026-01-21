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

struct SplitInternalEventWithMetadata {
    let type: SplitInternalEvent
    let metadata: EventMetadata?
    var extra: Any?
    
    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil, extra: Any? = nil) {
        self.type = type
        self.metadata = metadata
        self.extra = extra
    }
} 
