//
//  SplitInternalEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

public enum SplitInternalEvent {
    case mySegmentsAreReady
    case splitsAreReady
    case sdkReadyTimeoutReached
    case splitsAreUpdated
    case mySegmentsAreUpdated
}
