//
//  ContainsAllOfSetMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation



public class ContainsAllOfSetMatcher: BaseMatcher, MatcherProtocol {
    
    var data: Set<String>?
    
    //--------------------------------------------------------------------------------------------------
    public init(data:[String]?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        
        if let dataElements = data {
            
            let set: Set<String> = Set(dataElements.map { $0 })
            self.data = set
            
        }
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matchValueSet = matchValue as? Set<String>, let dataElements = data else {
            
            return false
            
        }
        
        print("KEY: \(matchValueSet)")
        
        return dataElements.isSubset(of: matchValueSet)
        
    }
    //--------------------------------------------------------------------------------------------------
    
    
}

