//  Created by Martin Cardozo on 06/06/2025

import Foundation

@objc public class EventMetadata: NSObject {
    var type: EventMetadataType
    var data: String = ""

    init(type: EventMetadataType, data: String) {
        self.type = type
        self.data = data
    }
}

@objc enum EventMetadataType: Int {
    case FLAGS_UPDATED
    case FLAGS_KILLED
    case SEGMENTS_UPDATED
    case LARGE_SEGMENTS_UPDATED
    case RULE_BASED_SEGMENTS_UPDATED
    
    public func toString() -> String {
        switch self {
            case .FLAGS_UPDATED: "FLAGS_UPDATED"
            case .FLAGS_KILLED: "FLAGS_KILLED"
            case .SEGMENTS_UPDATED: "SEGMENTS_UPDATED"
            case .LARGE_SEGMENTS_UPDATED: "LARGE_SEGMENTS_UPDATED"
            case .RULE_BASED_SEGMENTS_UPDATED: "RULE_BASED_SEGMENTS_UPDATED"
        }
    }
}
