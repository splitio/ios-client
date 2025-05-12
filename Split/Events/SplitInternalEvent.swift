//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

enum SplitEventCase {
    case mySegmentsUpdated
    case myLargeSegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case myLargeSegmentsLoadedFromCache
    case splitsLoadedFromCache
    case attributesLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
    case splitError
}

struct SplitInternalEvent: Equatable {
    let type: SplitEventCase
    let metadata: SplitKeyValue?
    
    init(type: SplitEventCase, metadata: SplitKeyValue? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    static func == (lhs: SplitInternalEvent, rhs: SplitInternalEvent) -> Bool {
        return lhs.type == rhs.type && lhs.metadata == rhs.metadata
    }
}
