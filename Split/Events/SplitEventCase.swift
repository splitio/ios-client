//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

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

struct SplitInternalEvent: Equatable {
    let type: SplitInternalEventCase
    let metadata: NSDictionary?
    
    init(type: SplitInternalEventCase, metadata: NSDictionary? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    static func == (lhs: SplitInternalEvent, rhs: SplitInternalEvent) -> Bool {
        return lhs.type == rhs.type 
    }
}
