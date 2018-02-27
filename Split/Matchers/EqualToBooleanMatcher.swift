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
        
        guard let matchValueBool = matchValue, let booleanData = data else {
            
            return false
            
        }
        
        if let newBooleanValue = matchValueBool as? Bool {
            
            return newBooleanValue == booleanData
        }
        
        if let stringBoolean = matchValueBool as? String {
            
            let lowerCaseStringBoolean = stringBoolean.lowercased()
            
            let booleanValue = Bool(lowerCaseStringBoolean)
            
            return booleanValue == booleanData
        }
        
        
        return false
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}

