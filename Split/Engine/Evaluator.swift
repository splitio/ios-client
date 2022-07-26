//
//  Evaluator.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation
// swiftlint:disable function_body_length
struct EvaluationResult {
    var treatment: String
    var label: String
    var changeNumber: Int64?
    var configuration: String?

    init(treatment: String, label: String, changeNumber: Int64? = nil, configuration: String? = nil) {
        self.treatment = treatment
        self.label = label
        self.changeNumber = changeNumber
        self.configuration = configuration
    }
}

struct EvalValues {
    let matchValue: Any?
    let matchingKey: String
    let bucketingKey: String?
    let attributes: [String: Any]?

    init(matchValue: Any?, matchingKey: String, bucketingKey: String? = nil, attributes: [String: Any]? = nil) {
        self.matchValue = matchValue
        self.matchingKey = matchingKey
        self.bucketingKey = bucketingKey
        self.attributes = attributes
    }
}

// Components needed
struct EvalContext {
    let evaluator: Evaluator?
    let mySegmentsStorage: MySegmentsStorage?
}

protocol Evaluator {
    func evalTreatment(matchingKey: String, bucketingKey: String?,
                       splitName: String, attributes: [String: Any]?) throws -> EvaluationResult
}

class DefaultEvaluator: Evaluator {
    // Internal for testing purposes
    var splitter: SplitterProtocol = Splitter.shared
    private let splitsStorage: SplitsStorage
    private let mySegmentsStorage: MySegmentsStorage

    init(splitsStorage: SplitsStorage, mySegmentsStorage: MySegmentsStorage) {
        self.splitsStorage = splitsStorage
        self.mySegmentsStorage = mySegmentsStorage
    }

    func evalTreatment(matchingKey: String, bucketingKey: String?,
                       splitName: String, attributes: [String: Any]?) throws -> EvaluationResult {

        guard let split = splitsStorage.get(name: splitName),
            split.status != .archived else {
                Logger.w("The SPLIT definition for '\(splitName)' has not been found")
                return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.splitNotFound)
        }

        let changeNumber = split.changeNumber ?? -1
        let defaultTreatment  = split.defaultTreatment ?? SplitConstants.control
        if let killed = split.killed, killed {
            return EvaluationResult(treatment: defaultTreatment,
                                    label: ImpressionsConstants.killed,
                                    changeNumber: changeNumber,
                                    configuration: split.configurations?[defaultTreatment])
        }

        var inRollOut: Bool = false
        var splitAlgo: Algorithm = Algorithm.legacy

        if let rawAlgo = split.algo, let algo = Algorithm.init(rawValue: rawAlgo) {
            splitAlgo = algo
        }

        let bucketKey = selectBucketKey(matchingKey: matchingKey, bucketingKey: bucketingKey)

        guard let conditions: [Condition] = split.conditions,
            let trafficAllocationSeed = split.trafficAllocationSeed,
            let seed = split.seed else {
                return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.exception)
        }

        do {
            for condition in conditions {
                if !inRollOut && condition.conditionType == ConditionType.rollout {
                    if let trafficAllocation = split.trafficAllocation, trafficAllocation < 100 {
                        let bucket: Int64 = splitter.getBucket(seed: trafficAllocationSeed,
                                                               key: bucketKey,
                                                               algo: splitAlgo)
                        if bucket > trafficAllocation {
                            return EvaluationResult(treatment: defaultTreatment,
                                                    label: ImpressionsConstants.notInSplit,
                                                    changeNumber: changeNumber,
                                                    configuration: split.configurations?[defaultTreatment])
                        }
                        inRollOut = true
                    }
                }

                // Returns the first condition that match.
                let values = EvalValues(matchValue: matchingKey, matchingKey: matchingKey,
                                        bucketingKey: bucketKey, attributes: attributes)
                if try condition.match(values: values, context: getContext()) {
                    let key: Key = Key(matchingKey: matchingKey, bucketingKey: bucketKey)
                    let treatment = splitter.getTreatment(key: key, seed: seed, attributes: attributes,
                                                          partions: condition.partitions, algo: splitAlgo)
                    return EvaluationResult(treatment: treatment, label: condition.label!,
                                            changeNumber: changeNumber,
                                            configuration: split.configurations?[treatment])
                }
            }
            let result = EvaluationResult(treatment: defaultTreatment,
                                          label: ImpressionsConstants.noConditionMatched,
                                          changeNumber: changeNumber,
                                          configuration: split.configurations?[defaultTreatment])
            return result
        } catch EvaluatorError.matcherNotFound {
            Logger.e("The matcher has not been found")
            return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.matcherNotFound,
                                    changeNumber: changeNumber)
        }
    }

    private func getContext() -> EvalContext {
        return EvalContext(evaluator: self, mySegmentsStorage: mySegmentsStorage)
    }

    private func selectBucketKey(matchingKey: String, bucketingKey: String?) -> String {
        if let key = bucketingKey, !key.isEmpty() {
            return key
        }
        return matchingKey
    }
}
