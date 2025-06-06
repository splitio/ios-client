//  Created by Martin Cardozo on 06/06/2025

@objc enum MetadataType: Int {
    case FLAG_UPDATED
    case FLAG_KILLED
    case SEGMENT_UPDATED
    case LARGE_SEGMENT_UPDATED
    case RULE_BASED_SEGMENT_UPDATED
    
    public func toString() -> String {
        switch self {
            case .FLAG_UPDATED:
                return "FLAG_UPDATED"
            case .FLAG_KILLED:
                return "FLAG_KILLED"
            case .SEGMENT_UPDATED:
                return "SEGMENT_UPDATED"
            case .LARGE_SEGMENT_UPDATED:
                return "LARGE_SEGMENT_UPDATED"
            case .RULE_BASED_SEGMENT_UPDATED:
                return "RULE_BASED_SEGMENT_UPDATED"
        }
    }
}
