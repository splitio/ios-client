//
//  EqualToBooleanMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/23/17.
//

import Foundation

class EqualToBooleanMatcher: BaseMatcher, MatcherProtocol {

    var data: Bool?

    init(data: Bool?, splitClient: DefaultSplitClient? = nil, negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil) {

        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool {

        guard let matchValueBool = matchValue, let booleanData = data else {
            return false
        }

        if let newBooleanValue = matchValueBool as? Bool {
            return newBooleanValue == booleanData
        }

        if let stringBoolean = matchValueBool as? String {
            let lowerCaseStringBoolean = stringBoolean.lowercased()
            let booleanValue = Bool(lowerCaseStringBoolean)
            return booleanValue == booleanData
        }
        return false
    }
}
