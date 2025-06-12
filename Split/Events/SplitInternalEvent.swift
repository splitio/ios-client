//  Created by Sebastian Arrubia on 4/16/18.

import Foundation

struct SplitInternalEventWithMetadata: Equatable {
    let type: SplitInternalEvent
    let metadata: EventMetadata?

    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    public static func == (lhs: SplitInternalEventWithMetadata, rhs: SplitInternalEventWithMetadata) -> Bool {
        return lhs.type == rhs.type && lhs.metadata == rhs.metadata
    }
    
    func isSameType(_ other: SplitInternalEventWithMetadata) -> Bool {
        return self.type == other.type
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
}
