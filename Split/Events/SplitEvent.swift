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

@objc public class SplitMetadata: NSObject {
    var type: String = ""
    var value: String = ""
    
    init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}

@objcMembers public class SplitEvent: NSObject {
    let type: SplitEventCase
    let metadata: SplitMetadata?
    
    @objc public init(type: SplitEventCase, metadata: SplitMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SplitEvent else { return false }
        return self.type == other.type
    }
}

