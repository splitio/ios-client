//
//  MatchesStringMatcher.swift
//  Alamofire
//
//  Created by Natalia  Stele on 11/23/17.
//


import Foundation

public class MatchesStringMatcher: BaseMatcher, MatcherProtocol {
    
    var data: String?

    //--------------------------------------------------------------------------------------------------
    public init(data: String?, splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.data = data
    }
    //--------------------------------------------------------------------------------------------------
    
    func dateFromInt(number: Int64) -> Date {
        
        return Date(timeIntervalSince1970: TimeInterval(number))
        
    }
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String : Any]?) -> Bool {
        
        guard let matcherData = data, let keyValue = matchValue as? String else {
            
            return false
            
        }
        if keyValue.range(of: matcherData, options: .regularExpression, range: nil, locale: nil) != nil {
            
            return true
            
        } else {
            
            return false
            
        }
  
    }
    //--------------------------------------------------------------------------------------------------
    
}

