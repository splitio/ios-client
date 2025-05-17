//  Created by Martin Cardozo on 17/05/2025
//  Copyright © 2025 Split. All rights reserved.

import Foundation

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
