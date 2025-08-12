//
//  SplitEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

@objcMembers public class SplitEventWithMetadata: NSObject {
    let type: SplitEvent
    let metadata: EventMetadata?
    
    @objc public init(type: SplitEvent, metadata: EventMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
}

@objc public enum SplitEvent: Int {
    case sdkReady
    case sdkReadyTimedOut
    case sdkReadyFromCache
    case sdkUpdated
    case sdkError

    public func toString() -> String {
        switch self {
            case .sdkReady:
                return "SDK_READY"
            case .sdkUpdated:
                return "SDK_UPDATE"
            case .sdkReadyTimedOut:
                return "SDK_READY_TIMED_OUT"
            case .sdkReadyFromCache:
                return "SDK_READY_FROM_CACHE"
            case .sdkError:
                return "SDK_ERROR"
        }
    }
}
