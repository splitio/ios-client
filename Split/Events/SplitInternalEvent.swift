//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

public enum SplitInternalEvent {
    case mySegmentsUpdated
    case splitsUpdated
    case mySegmentsLoadedFromCache
    case splitsLoadedFromCache
    case sdkReadyTimeoutReached
    case splitKilledNotification
}
