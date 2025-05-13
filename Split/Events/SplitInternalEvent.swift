//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.

import Foundation

struct SplitInternalEvent {
    let type: SplitInternalEventCase
    let metadata: SplitMetadata?
    
    init(_ type: SplitInternalEventCase, metadata: SplitMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    static func == (lhs: SplitInternalEvent, rhs: SplitInternalEvent) -> Bool {
        return lhs.type == rhs.type 
    }
}

enum SplitInternalEventCase {
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
