//  Created by Sebastian Arrubia on 4/16/18.

import Foundation

struct SplitInternalEventWithMetadata: Equatable {
    let type: SplitInternalEvent
    let metadata: EventMetadata?

    init(_ type: SplitInternalEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
}

enum SplitInternalEvent {
    // Events
    case mySegmentsUpdated
    case myLargeSegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case myLargeSegmentsLoadedFromCache
    case splitsLoadedFromCache
    case attributesLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
    
    // Errors
    case sdkError
}
