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
    private let clientQueue = DispatchQueue(label: "split-condition", target: DispatchQueue.global())
    private weak var wrappedClient: InternalSplitClient?
    var client: InternalSplitClient? {
        get {
            var localClient: InternalSplitClient?
            clientQueue.sync {
                localClient = wrappedClient
            }
            return localClient
        }

        set {
            clientQueue.sync {
                wrappedClient = newValue
            }
        }
    }

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

    func match(matchValue: Any?, matchingKey: String, bucketingKey: String?, attributes: [String: Any]?) throws -> Bool {

        if let matcherG = self.matcherGroup, let matchers = matcherG.matchers {
            var results: [Bool] = []
            for matcher in matchers {
                matcher.client = self.client
                let matcherEvaluator = try matcher.getMatcher()
                var result: Bool = false

                if matcherEvaluator.getMatcherType() != MatcherType.dependency {
                    // scenario 1: no attr in matcher
                    // e.g. if user is in segment all then split 100:on
                    if !matcherEvaluator.matcherHasAttribute() {
                        result = matcherEvaluator.evaluate(matchValue: matchValue,
                                                           matchingKey: matchingKey,
                                                           bucketingKey: nil, attributes: nil)
                    } else {
                        // scenario 2: attribute provided but no attribute value provided. Matcher does not match
                        // e.g. if user.age is >= 10 then split 100:on
                        let att = matcherEvaluator.getAttribute()!
                        if attributes == nil || attributes![att] == nil {
                            result = false

                        } else {
                            // instead of using the user id, we use the attribute value for evaluation
                            result = matcherEvaluator.evaluate(matchValue: attributes![att],
                                                               matchingKey: matchingKey,
                                                               bucketingKey: nil,
                                                               attributes: nil)
                        }
                    }
                } else if matcherEvaluator.getMatcherType() == MatcherType.dependency {
                        result = matcherEvaluator.evaluate(matchValue: matchValue,
                                                           matchingKey: matchingKey,
                                                           bucketingKey: bucketingKey,
                                                           attributes: attributes)
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
