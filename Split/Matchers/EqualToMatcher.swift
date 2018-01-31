//
//  EqualToMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/23/17.
//

import Foundation

public class EqualToMatcher: BaseMatcher, MatcherProtocol {
    
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
            let keyDate = Date(timeIntervalSince1970: TimeInterval(keyValue))
            let atributteDate = Date(timeIntervalSince1970: backendTimeInterval)
            return keyDate == atributteDate
            
        case DataType.Number:
            guard let keyValue = matchValue as? Int64 else {return false}
            return keyValue == value
            
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}

