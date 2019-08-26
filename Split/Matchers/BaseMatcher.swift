//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation

class BaseMatcher: NSObject {

    var splitClient: InternalSplitClient?
    var negate: Bool?
    var attribute: String?
    var type: MatcherType?

    init(splitClient: InternalSplitClient? = nil, negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil) {

        self.splitClient = splitClient
        self.negate = negate
        self.attribute = attribute
        self.type = type
    }

    func isNegate() -> Bool {
        return self.negate ?? false
    }

    func hasAttribute() -> Bool {
        return self.attribute != nil
    }

    func getAttribute() -> String? {
        return self.attribute
    }

    func getMatcherType() -> MatcherType {
        return self.type!
    }

    func matcherHasAttribute() -> Bool {
        return self.attribute != nil
    }
}
