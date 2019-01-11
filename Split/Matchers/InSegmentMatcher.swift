//
//  InSegmentMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation



public class InSegmentMatcher: BaseMatcher, MatcherProtocol {
    
    var data: UserDefinedSegmentMatcherData?
    
    //--------------------------------------------------------------------------------------------------
    public init(data: UserDefinedSegmentMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, attribute: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String : Any]?) -> Bool {
        
        // Match value is not used because it is matching key. My segments cache only has segments for that key cause
        // Split client is instantiated  based on it
        if let _ = matchValue as? String, let dataElements = data, let segmentName = dataElements.segmentName {
            if let segment = self.splitClient?.mySegmentsFetcher as? RefreshableMySegmentsFetcher {
                return segment.mySegmentsCache.isInSegments(name: segmentName)
            }
        }
        return false
    }
    //--------------------------------------------------------------------------------------------------
    
    
}
