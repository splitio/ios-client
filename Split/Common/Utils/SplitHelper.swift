//
//  SplitConditionHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
// swiftlint:disable inclusive_language
class SplitHelper {

    func createDefaultSplit(named splitName: String) -> Split {
        let split = Split()
        split.name = splitName
        split.defaultTreatment = SplitConstants.control
        split.status = .active
        split.algo = Algorithm.murmur3.rawValue
        split.trafficTypeName = "custom"
        split.trafficAllocation = 100
        split.trafficAllocationSeed = 1
        split.seed = 1
        return split
    }

    func createWhitelistCondition(keys: [String], treatment: String) -> Condition {

        let condition = Condition()
        let matcherGroup = MatcherGroup()
        let matcher = Matcher()
        let whiteListMatcherData = WhitelistMatcherData()
        let partition = Partition()

        condition.conditionType = ConditionType.whitelist
        matcherGroup.matcherCombiner = .and
        matcher.matcherType = MatcherType.whitelist
        whiteListMatcherData.whitelist = keys
        matcher.whitelistMatcherData = whiteListMatcherData
        partition.size = 100
        partition.treatment = treatment
        matcherGroup.matchers = [matcher]
        condition.matcherGroup = matcherGroup
        condition.partitions = [partition]
        condition.label = "LOCAL_\(keys)"

        return condition
    }

    func createRolloutCondition(treatment: String) -> Condition {
        let condition = Condition()
        let matcherGroup = MatcherGroup()
        let matcher = Matcher()
        let partition = Partition()

        condition.conditionType = ConditionType.rollout
        matcherGroup.matcherCombiner = .and
        matcher.matcherType = MatcherType.allKeys
        partition.size = 100
        partition.treatment = treatment

        matcherGroup.matchers = [matcher]
        condition.matcherGroup = matcherGroup
        condition.partitions = [partition]
        condition.label = "in segment all"

        return condition
    }
}
