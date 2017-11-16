//
//  MatcherProtocol.swift
//  Alamofire
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public protocol MatcherProtocol: NSObjectProtocol {

    func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String:Any]?) -> Bool
    func getAttribute() -> String?
    func getMatcherType() -> MatcherType
    func matcherHasAttribute() -> Bool
    func isNegate() -> Bool
    
}


//public extension MatcherProtocol {
//    
//    public func evaluate(matchValue: Any?, bucketingKey: String? = nil, atributtes: [String:Any]? = nil) -> Bool {
//        
//        return evaluate(matchValue: matchValue, bucketingKey: bucketingKey, atributtes: atributtes)
//    }
//
//}

