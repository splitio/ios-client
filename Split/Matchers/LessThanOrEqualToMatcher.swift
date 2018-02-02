//
//  LessThanOrEqualToMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation

public class LessThanOrEqualToMatcher: BaseMatcher, MatcherProtocol {
    
    var data: UnaryNumericMatcherData?
    
    
    //--------------------------------------------------------------------------------------------------
    public init(data: UnaryNumericMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matcherData = data, let dataType = matcherData.dataType, let value = matcherData.value else {
            return false
        }
        
        switch dataType {
            case DataType.DateTime:
                guard let keyValue = matchValue as? TimeInterval else {return false}
                let backendTimeInterval = TimeInterval(value/1000)
                let attributeTimeInterval = keyValue
                let attributeDate = DateTime.zeroOutSeconds(timestamp: attributeTimeInterval)
                let backendDate = DateTime.zeroOutSeconds(timestamp: backendTimeInterval)
                return  attributeDate <= backendDate
            case DataType.Number:
                guard let keyValue = matchValue as? Int64 else {return false}
                return keyValue <= value
        }
    }
}


