//
//  MatcherProtocol.swift
//  Alamofire
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public protocol MatcherProtocol: NSObjectProtocol {

    func evaluate(matchValue: Any?) -> Bool
    func getAttribute() -> String?
    func getMatcherType() -> MatcherType
    func matcherHasAttribute() -> Bool
    func isNegate() -> Bool
    
}
