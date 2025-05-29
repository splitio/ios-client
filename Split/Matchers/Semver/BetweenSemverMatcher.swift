//
//  BetweenSemverMatcher.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class BetweenSemverMatcher: BaseMatcher, MatcherProtocol {
    var startTarget: Semver?
    var endTarget: Semver?

    init(
        data: BetweenStringMatcherData?,
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        super.init(negate: negate, attribute: attribute, type: type)
        self.startTarget = Semver.build(version: data?.start as? String)
        self.endTarget = Semver.build(version: data?.end as? String)
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let keyValue = values.matchValue as? String,
              let startTarget = startTarget,
              let endTarget = endTarget else {
            return false
        }

        guard let keySemver = Semver.build(version: keyValue) else {
            return false
        }

        let result = keySemver.compare(to: startTarget) >= 0 && keySemver.compare(to: endTarget) <= 0

        Logger.d(
            "\(startTarget.getVersion()) <= \(keySemver.getVersion()) " +
                "<= \(endTarget.getVersion()) | Result: \(result)")

        return result
    }
}
