//
//  MatcherProtocol.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

protocol MatcherProtocol: NSObjectProtocol {
    func evaluate(values: EvalValues, context: EvalContext?) -> Bool
    func getAttribute() -> String?
    func getMatcherType() -> MatcherType
    func matcherHasAttribute() -> Bool
    func isNegate() -> Bool
}
