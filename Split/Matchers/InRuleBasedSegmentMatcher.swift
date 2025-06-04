//
//  InRuleBasedSegmentMatcher.swift
//  Split
//
//  Created by Split on 18/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

class InRuleBasedSegmentMatcher: BaseMatcher, MatcherProtocol {

    private var data: UserDefinedBaseSegmentMatcherData?

    init(data: UserDefinedBaseSegmentMatcherData?,
         negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let segmentName = data?.segmentName,
              let ruleBasedSegmentsStorage = context?.ruleBasedSegmentsStorage,
              let segment = ruleBasedSegmentsStorage.get(segmentName: segmentName) else {
            return false
        }

        if isExcluded(segment: segment, matchingKey: values.matchingKey,
                      values: values, context: context) {
            return false
        }

        return checkConditions(segment: segment, values: values, context: context)
    }

    /// returns true if the matchingKey or any of the segments is excluded
    private func isExcluded(segment: RuleBasedSegment, matchingKey: String,
                            values: EvalValues, context: EvalContext?) -> Bool {
        // no excluded property
        guard let excluded = segment.excluded else {
            return false
        }

        // check excluded keys
        if let excludedKeys = excluded.keys, excludedKeys.contains(matchingKey) {
            return true
        }

        // check excluded segments
        if let excludedSegments = excluded.segments {
            for segment in excludedSegments {
                guard let name = segment.name else {
                    continue
                }

                if segment.isStandard() {
                    if context?.mySegmentsStorage?.getAll(forKey: matchingKey).contains(name) ?? false {
                        return true
                    }
                }

                if segment.isRuleBased() {
                    let matcherData = UserDefinedSegmentMatcherData()
                    matcherData.segmentName = name
                    if InRuleBasedSegmentMatcher(data: matcherData).evaluate(values: values, context: context) {
                        return true
                    }
                }

                if segment.isLarge() {
                    if context?.myLargeSegmentsStorage?.getAll(forKey: matchingKey).contains(name) ?? false {
                        return true
                    }
                }
            }
        }

        return false
    }

    private func checkConditions(segment: RuleBasedSegment, values: EvalValues, context: EvalContext?) -> Bool {
        guard let conditions = segment.conditions else {
            return false
        }

        for condition in conditions {
            do {
                if try condition.match(values: values, context: context) {
                    return true
                }
            } catch {
                Logger.e("Error evaluating condition in InRuleBasedSegmentMatcher: \(error)")
                continue
            }
        }

        return false
    }
}
