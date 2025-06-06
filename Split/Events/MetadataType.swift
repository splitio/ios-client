//  Created by Martin Cardozo on 06/06/2025

@objc enum MetadataType: Int {
    case FLAG_UPDATED
    case FLAG_KILLED
    case SEGMENT_UPDATED
    case LARGE_SEGMENT_UPDATED
    case RULE_BASED_SEGMENT_UPDATED
    
    var stringValue: String {
        return String(describing: self)
    }
}
