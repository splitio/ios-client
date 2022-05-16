//
//  Whitelist.swift
//  Split
//
//  Created by Natalia  Stele on 11/22/17.
//

import Foundation

// swiftlint:disable inclusive_language
class Whitelist: BaseMatcher, MatcherProtocol {

    var data: [String]?

    init(data: [String]?, splitClient: DefaultSplitClient? = nil, negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {

        guard let matchValueString = values.matchValue as? String, let dataElements = data else {
            return false
        }
        return dataElements.contains(matchValueString)
    }
}
