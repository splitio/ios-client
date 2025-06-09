//  Created by Sebastian Arrubia on 4/16/18.

import Foundation

struct SplitInternalEventWithMetadata {
    let type: SplitInternalEvent
    let metadata: EventMetadata?

    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }

    static func == (lhs: SplitInternalEventWithMetadata, rhs: SplitInternalEventWithMetadata) -> Bool {
        return lhs.type == rhs.type
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
