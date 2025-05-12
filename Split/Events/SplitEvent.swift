//
//  SplitEventCase.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

@objc public enum SplitEventCase: Int {
    case sdkReady
    case sdkReadyTimedOut
    case sdkReadyFromCache
    case sdkUpdated

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
        }
    }
}

@objcMembers public class SplitEvent: NSObject {
    let type: SplitEventCase
    let metadata: NSDictionary?
    
    @objc public init(type: SplitEventCase, metadata: NSDictionary? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SplitEvent else { return false }
        return self.type == other.type
    }
}

