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
    public init(data:[String]?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {

        guard let matchValueString = matchValue as? String, let dataElements = data else {
            
            return false
            
        }
        
        print("KEY: \(matchValueString)")
        
        var value: Bool = false
        
        for element in dataElements {
            
            if element.contains(matchValueString) {
                
                value = true
            }
            
        }
        
        return value
        
    }
    //--------------------------------------------------------------------------------------------------

    
}
