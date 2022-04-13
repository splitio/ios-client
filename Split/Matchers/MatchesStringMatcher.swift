//
//  MatchesStringMatcher.swift
//  Alamofire
//
//  Created by Natalia  Stele on 11/23/17.
//

import Foundation

class MatchesStringMatcher: BaseMatcher, MatcherProtocol {

    var data: String?

    init(data: String?,
         negate: Bool? = nil,
         attribute: String? = nil,
         type: MatcherType? = nil) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func dateFromInt(number: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(number))
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {

        guard let matcherData = data, let keyValue = values.matchValue as? String else {
            return false
        }

        if keyValue.range(of: matcherData, options: .regularExpression, range: nil, locale: nil) != nil {
            return true
        } else {
            return false
        }
    }
}
