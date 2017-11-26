//
//  GreaterThanOrEqualToMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 26/11/2017.
//

import Foundation

public class GreaterThanOrEqualToMatcher: BaseMatcher, MatcherProtocol {
    
    var data: UnaryNumericMatcherData?
    
    
    //--------------------------------------------------------------------------------------------------
    public init(data: UnaryNumericMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matcherData = data, let dataType = matcherData.dataType, let value = matcherData.value , let keyValue = matchValue as? Int64 else {
            
            return false
            
        }
        
        switch dataType {
            
        case DataType.DateTime:
            
            let keyDate = Date.dateFromInt(number: keyValue)
            let atributteDate = Date.dateFromInt(number: value)
            
            return keyDate >= atributteDate
            
        case DataType.Number:
            
            return keyValue >= value
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
}


