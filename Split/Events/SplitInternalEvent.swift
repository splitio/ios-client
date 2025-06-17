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
    case mySegmentsUpdated
    case myLargeSegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case myLargeSegmentsLoadedFromCache
    case splitsLoadedFromCache
    case attributesLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
//    
//    public func toString() -> String {
//        switch self {
//            case .mySegmentsUpdated:
//                return "mySegmentsUpdated"
//            case .myLargeSegmentsUpdated:
//                return "myLargeSegmentsUpdated"
//            case .splitsUpdated:
//                return "splitsUpdated"
//            case .mySegmentsLoadedFromCache:
//                return "mySegmentsLoadedFromCache"
//            case .myLargeSegmentsLoadedFromCache:
//                return "myLargeSegmentsLoadedFromCache"
//            case .splitsLoadedFromCache:
//                return "splitsLoadedFromCache"
//            case .attributesLoadedFromCache:
//                return "attributesLoadedFromCache"
//            case .sdkReadyTimeoutReached:
//                return "sdkReadyTimeoutReached"
//            case .splitKilledNotification:
//                return "splitKilledNotification"
//        }
//    }
}
