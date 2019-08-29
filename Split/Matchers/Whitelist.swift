//
//  Whitelist.swift
//  Split
//
//  Created by Natalia  Stele on 11/22/17.
//

import Foundation

class Whitelist: BaseMatcher, MatcherProtocol {

    var data: [String]?

    init(data: [String]?, splitClient: DefaultSplitClient? = nil, negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil) {

        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool {

        guard let matchValueString = matchValue as? String, let dataElements = data else {
            return false
        }
        return dataElements.contains(matchValueString)
    }
}
