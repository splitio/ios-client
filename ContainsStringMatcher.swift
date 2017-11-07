//
//  ContainsStringMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation



public class ContainsStringMatcher: BaseMatcher, MatcherProtocol {
    
    var data: [String]?
    
    //--------------------------------------------------------------------------------------------------
    public init(data:[String]?, negate: Bool) {
        
        super.init(splitClient: nil, negate: negate)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func match(matchValue: Any?, bucketingKey: String? ,atributtes: [String:Any]?) -> Bool {
        
        guard let matchValueString = matchValue as? String, let dataElements = data else {
            
            return false
            
        }
        
        for element in dataElements {
            
            if element.contains(matchValueString) {
                
                return negate(value: true)
            }
            
        }
        
        return negate(value: false)
    }
    //--------------------------------------------------------------------------------------------------

}
