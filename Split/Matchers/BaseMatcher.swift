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

    init(negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {

        self.negate = negate
        self.attribute = attribute
        self.type = type
    }

    func isNegate() -> Bool {
        self.negate ?? false
    }

    func getAttribute() -> String? {
        self.attribute
    }

    func getMatcherType() -> MatcherType {
        self.type!
    }

    func matcherHasAttribute() -> Bool {
        self.attribute != nil
    }
}
