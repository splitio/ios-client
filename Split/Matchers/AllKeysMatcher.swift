//
//  AllKeysMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

class AllKeysMatcher: BaseMatcher, MatcherProtocol {

    init(negate: Bool? = false) {
        super.init(negate: negate, type: MatcherType.allKeys)
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        if values.matchValue == nil {
            return false
        }

        return true
    }
}
