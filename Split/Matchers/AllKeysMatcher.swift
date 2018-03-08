//
//  AllKeysMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

public class AllKeysMatcher: BaseMatcher, MatcherProtocol  {
    

    //--------------------------------------------------------------------------------------------------
     public init(negate: Bool? = false) {
        
        super.init(negate: negate, type: MatcherType.AllKeys)
        
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        if matchValue == nil {
            
            return false
        }
        
        return true
    }
}
