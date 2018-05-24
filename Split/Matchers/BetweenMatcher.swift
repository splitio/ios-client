//
//  BetweenMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 26/11/2017.
//

import Foundation

public class BetweenMatcher: BaseMatcher, MatcherProtocol {
    
    var data: BetweenMatcherData?
    
    
    //--------------------------------------------------------------------------------------------------
    public init(data: BetweenMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, attribute: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String : Any]?) -> Bool {
        
        guard let matcherData = data, let dataType = matcherData.dataType, let start = matcherData.start, let end = matcherData.end else {
            
            return false
            
        }
        
        switch dataType {
            
        case DataType.DateTime:
            guard let keyValue = matchValue as? TimeInterval else {return false}
            let backendTimeIntervalStart = TimeInterval(start/1000) //Backend is in millis
            let backendTimeIntervalEnd = TimeInterval(end/1000) //Backend is in millis
            let attributeTimeInterval = keyValue
            
            let attributeDate = DateTime.zeroOutSeconds(timestamp: attributeTimeInterval)
            let backendDateStart = DateTime.zeroOutSeconds(timestamp: backendTimeIntervalStart)
            let backendDateEnd = DateTime.zeroOutSeconds(timestamp: backendTimeIntervalEnd)

            return attributeDate >= backendDateStart && attributeDate <= backendDateEnd
            
        case DataType.Number:
            guard let keyValue = matchValue as? Int64 else {return false}
            return keyValue >= start && keyValue <= end
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
}


