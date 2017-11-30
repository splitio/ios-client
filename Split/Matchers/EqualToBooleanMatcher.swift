//
//  EqualToBooleanMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/23/17.
//

import Foundation

public class EqualToBooleanMatcher: BaseMatcher, MatcherProtocol {
    
    var data: Bool?
    
    //--------------------------------------------------------------------------------------------------
    public init(data: Bool?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matchValueBool = matchValue as? Bool, let boolenData = data else {
            
            return false
            
        }
        
        print("KEY: \(matchValueBool)")
        
        return matchValueBool == boolenData
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}

