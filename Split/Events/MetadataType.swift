//  Created by Martin Cardozo on 06/06/2025

@objc enum MetadataType: Int {
    case FLAGS_UPDATED
    case FLAGS_KILLED
    case SEGMENTS_UPDATED
    case LARGE_SEGMENTS_UPDATED
    case RULE_BASED_SEGMENTS_UPDATED
    
    var stringValue: String {
        return String(describing: self)
    }
}
