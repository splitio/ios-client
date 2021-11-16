//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

enum SplitInternalEvent {
    case mySegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case splitsLoadedFromCache
    case attributesLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
}
