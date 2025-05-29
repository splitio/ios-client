//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

class BaseMatcher: NSObject {
    var negate: Bool?
    var attribute: String?
    var type: MatcherType?

    init(
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        self.negate = negate
        self.attribute = attribute
        self.type = type
    }

    func isNegate() -> Bool {
        return negate ?? false
    }

    func getAttribute() -> String? {
        return attribute
    }

    func getMatcherType() -> MatcherType {
        return type!
    }

    func matcherHasAttribute() -> Bool {
        return attribute != nil
    }
}
