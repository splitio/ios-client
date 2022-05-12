//
//  Condition.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

class Condition: NSObject, Codable {

    var conditionType: ConditionType?
    var matcherGroup: MatcherGroup?
    var partitions: [Partition]?
    var label: String?

    enum CodingKeys: String, CodingKey {
        case conditionType
        case matcherGroup
        case partitions
        case label
    }

    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            conditionType = try? values.decode(ConditionType.self, forKey: .conditionType)
            matcherGroup = try? values.decode(MatcherGroup.self, forKey: .matcherGroup)
            partitions = try? values.decode([Partition].self, forKey: .partitions)
            label = (try? values.decode(String.self, forKey: .label)) ?? ""
        }
    }

    func match(values: EvalValues, context: EvalContext) throws -> Bool {

        if let matcherG = self.matcherGroup, let matchers = matcherG.matchers {
            var results: [Bool] = []
            for matcher in matchers {
                let matcherEvaluator = try matcher.getMatcher()
                var result: Bool = false

                if matcherEvaluator.getMatcherType() != MatcherType.dependency {
                    // scenario 1: no attr in matcher
                    // e.g. if user is in segment all then split 100:on
                    if !matcherEvaluator.matcherHasAttribute() {
                        let newValues = EvalValues(matchValue: values.matchValue,
                                                   matchingKey: values.matchingKey,
                                                   bucketingKey: nil,
                                                   attributes: nil)
                        result = matcherEvaluator.evaluate(values: newValues, context: context)
                    } else {
                        // scenario 2: attribute provided but no attribute value provided. Matcher does not match
                        // e.g. if user.age is >= 10 then split 100:on
                        // Next line: Should not  be null, but just in case to avoid a crash
                        let att = matcherEvaluator.getAttribute() ?? "null"
                        if values.attributes == nil || values.attributes![att] == nil {
                            result = false
                        } else {
                            // instead of using the user id, we use the attribute value for evaluation
                            let newValues = EvalValues(matchValue: values.attributes?[att] ?? "null",
                                                       matchingKey: values.matchingKey,
                                                       bucketingKey: nil,
                                                       attributes: nil)
                            result = matcherEvaluator.evaluate(values: newValues, context: context)
                        }
                    }
                } else if matcherEvaluator.getMatcherType() == MatcherType.dependency {
                        result = matcherEvaluator.evaluate(values: values, context: context)
                }

                let lastEvaluation = matcherEvaluator.isNegate() ? !result : result
                results.append(lastEvaluation)
            }

            switch matcherG.matcherCombiner {
            case .and?:
                return (matcherG.matcherCombiner?.combineAndResults(partialResults: results))!
            case .none:
                return (matcherG.matcherCombiner?.combineAndResults(partialResults: results))!
            }
        }
        return false
    }
}
