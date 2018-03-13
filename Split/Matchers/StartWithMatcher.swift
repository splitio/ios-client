//
//  StartWithMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/22/17.
//

import Foundation



public class StartWithMatcher: BaseMatcher, MatcherProtocol {
    
    var data: [String]?
    
    //--------------------------------------------------------------------------------------------------
    public init(data:[String]?, splitClient: SplitClient? = nil, negate: Bool? = nil, attribute: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String : Any]?) -> Bool {
        
        guard let matchValueString = matchValue as? String, let dataElements = data else {
            
            return false
            
        }
                
        for element in dataElements {
            
            if matchValueString.starts(with: element) {
                
                return true
            
            }
            
        }
        
        return false
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}

