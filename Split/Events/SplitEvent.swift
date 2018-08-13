//
//  SplitEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

public enum SplitEvent {
    case sdkReady
    case sdkReadyTimedOut
    
    func toString() -> String {
        switch self {
        case .sdkReady:
            return "SDK_READY"
        case .sdkReadyTimedOut:
            return "SDK_READY_TIMED_OUT"
        }
    }
}
