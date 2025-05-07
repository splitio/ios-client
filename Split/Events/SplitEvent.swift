//
//  SplitEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

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

@objcMembers
public class SplitEventWithMetadata: NSObject {
    let type: SplitEvent
    let metadata: [String: Any]?
    
    @objc public init(type: SplitEvent, metadata: [String : Any]? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SplitEventWithMetadata else { return false }
        return self.type == other.type
    }
    
    public override var hash: Int {
        return type.hashValue
    }
}

