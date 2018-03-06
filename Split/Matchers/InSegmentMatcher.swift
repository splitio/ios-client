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
    public init(data: UserDefinedSegmentMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matchValueString = matchValue as? String, let dataElements = data, let segmentName = dataElements.segmentName else {
            
            return false
            
        }
                
        let segment = self.splitClient?.mySegmentsFetcher as? RefreshableMySegmentsFetcher
        
        return (segment?.mySegmentsCache.isInSegment(segmentName: segmentName, key:matchValueString))!
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}
