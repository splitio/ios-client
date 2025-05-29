//
//  StartWithMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/22/17.
//

import Foundation

class StartWithMatcher: BaseMatcher, MatcherProtocol {
    var data: [String]?

    init(
        data: [String]?,
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let matchValueString = values.matchValue as? String, let dataElements = data else {
            return false
        }

        for element in dataElements {
            if matchValueString.starts(with: element) {
                return true
            }
        }
        return false
    }
}
