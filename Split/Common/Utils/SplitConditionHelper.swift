//
//  SplitConditionHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class SplitConditionHelper {
    
    func createWhitelistCondition(key: String, treatment: String) -> Condition {
        
        let condition = Condition()
        let matcherGroup = MatcherGroup()
        let matcher = Matcher()
        let whiteListMatcherData = WhitelistMatcherData()
        let partition = Partition()
        
        condition.conditionType = ConditionType.Whitelist
        matcherGroup.matcherCombiner = MatcherCombiner.And
        matcher.matcherType = MatcherType.Whitelist
        whiteListMatcherData.whitelist = [key]
        matcher.whitelistMatcherData = whiteListMatcherData
        partition.size = 100
        partition.treatment = treatment
        matcherGroup.matchers = [matcher]
        condition.matcherGroup = matcherGroup
        condition.partitions = [partition]
        condition.label = "LOCAL_\(key)"
        
        return condition
    }
    
    func createRolloutCondition(treatment: String) -> Condition {
        let condition = Condition()
        let matcherGroup = MatcherGroup()
        let matcher = Matcher()
        let partition = Partition()
        
        condition.conditionType = ConditionType.Rollout
        matcherGroup.matcherCombiner = MatcherCombiner.And
        matcher.matcherType = MatcherType.AllKeys
        partition.size = 100
        partition.treatment = treatment
        
        matcherGroup.matchers = [matcher]
        condition.matcherGroup = matcherGroup
        condition.partitions = [partition]
        condition.label = "in segment all"
        
        return condition
    }
}
