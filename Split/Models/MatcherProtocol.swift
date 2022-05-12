//
//  MatcherProtocol.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

protocol MatcherProtocol: NSObjectProtocol {
    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool
    func getAttribute() -> String?
    func getMatcherType() -> MatcherType
    func matcherHasAttribute() -> Bool
    func isNegate() -> Bool
}
