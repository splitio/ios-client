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
    public init(data: BetweenMatcherData?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matcherData = data, let dataType = matcherData.dataType, let start = matcherData.start, let end = matcherData.end , let keyValue = matchValue as? Int64 else {
            
            return false
            
        }
        
        switch dataType {
            
        case DataType.DateTime:
            
            let keyDate = Date.dateFromInt(number: keyValue)
            let startDate = Date.dateFromInt(number: start)
            let endDate = Date.dateFromInt(number: end)

            return keyDate.isBetweeen(date: startDate, andDate: endDate)
            
        case DataType.Number:
            
            return keyValue >= start && keyValue <= end
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
}


