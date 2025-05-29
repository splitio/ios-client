//
//  LessThanOrEqualToSemverMatcher.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class LessThanOrEqualToSemverMatcher: BaseMatcher, MatcherProtocol {
    var target: Semver?

    init(
        data: String?,
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        super.init(negate: negate, attribute: attribute, type: type)
        self.target = Semver.build(version: data)
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let key = values.matchValue as? String, let target = target else {
            return false
        }

        guard let keySemver = Semver.build(version: key) else {
            return false
        }

        let result = keySemver.compare(to: target) <= 0

        Logger.d("\(keySemver.getVersion()) <= \(target.getVersion()) | Result: \(result)")

        return result
    }
}
