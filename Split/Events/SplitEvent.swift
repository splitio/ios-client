//
//  SplitEvent.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

// All events (internal & external) supports metadata.
// Internal errors will be propagated as events "(.sdkError)" to the customer handler. The error info will travel as the event metadata.

@objcMembers public class SplitEventWithMetadata: NSObject {
    let type: SplitEvent
    let metadata: SplitMetadata?
    
    @objc public init(type: SplitEvent, metadata: SplitMetadata? = nil) {
        self.type = type
        self.metadata = metadata
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SplitEventWithMetadata else { return false }
        return self.type == other.type
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

@objc public class SplitMetadata: NSObject {
    var type: SplitMetadataType
    var data: String = ""
    
    init(type: SplitMetadataType, data: String) {
        self.type = type
        self.data = data
    }
}

enum SplitMetadataType: Int {
    case FEATURE_FLAGS_SYNC_ERROR
    case SEGMENTS_SYNC_ERROR
    
    public func toString() -> String {
        switch self {
            case .FEATURE_FLAGS_SYNC_ERROR:
                return "FEATURE_FLAGS_SYNC_ERROR"
            case .SEGMENTS_SYNC_ERROR:
                return "SEGMENTS_SYNC_ERROR"
            
        }
    }
}

