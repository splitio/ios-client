//
//  InListSemverMatcher.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class InListSemverMatcher: BaseMatcher, MatcherProtocol {
    var targetList: Set<Semver> = Set()

    init(
        data: [String]?,
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        super.init(negate: negate, attribute: attribute, type: type)
        self.targetList = Set<Semver>(data?.compactMap { item in
            Semver.build(version: item)
        } ?? [])
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let key = values.matchValue as? String else {
            return false
        }

        if targetList.isEmpty {
            return false
        }

        guard let keySemver = Semver.build(version: key) else {
            return false
        }

        return targetList.contains { target in
            target == keySemver
        }
    }
}
