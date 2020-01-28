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

protocol Evaluator {
    func evalTreatment(matchingKey: String, bucketingKey: String?,
                       splitName: String, attributes: [String: Any]?) throws -> EvaluationResult
}

class DefaultEvaluator: Evaluator {
    var splitFetcher: SplitFetcher?
    var mySegmentsFetcher: MySegmentsFetcher?
    weak var splitClient: InternalSplitClient? {

        didSet {
            self.splitFetcher = self.splitClient?.splitFetcher
            self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
        }
    }
    var splitter: SplitterProtocol = Splitter.shared

    init(splitClient: InternalSplitClient? = nil) {

            self.splitClient = splitClient
            self.splitFetcher = self.splitClient?.splitFetcher
            self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
    }

    func evalTreatment(matchingKey: String, bucketingKey: String?,
                       splitName: String, attributes: [String: Any]?) throws -> EvaluationResult {

        if let split: Split = splitFetcher?.fetch(splitName: splitName), split.status != .archived {
            let changeNumber = split.changeNumber ?? -1
            let defaultTreatment  = split.defaultTreatment ?? SplitConstants.control
            if let killed = split.killed, killed {
                return EvaluationResult(treatment: defaultTreatment,
                                        label: ImpressionsConstants.killed,
                                        changeNumber: changeNumber,
                                        configuration: split.configurations?[defaultTreatment])
            }

            var bucketKey: String?
            var inRollOut: Bool = false
            var splitAlgo: Algorithm = Algorithm.legacy

            if let rawAlgo = split.algo, let algo = Algorithm.init(rawValue: rawAlgo) {
                splitAlgo = algo
            }

            bucketKey = !(bucketingKey ?? "").isEmpty() ? bucketingKey : matchingKey

            guard let conditions: [Condition] = split.conditions,
                let trafficAllocationSeed = split.trafficAllocationSeed,
                let seed = split.seed else {
                return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.exception)
            }

            do {
                for condition in conditions {
                    condition.client = splitClient
                    if !inRollOut && condition.conditionType == ConditionType.rollout {
                        if let trafficAllocation = split.trafficAllocation, trafficAllocation < 100 {
                            let bucket: Int64 = splitter.getBucket(seed: trafficAllocationSeed,
                                                                   key: bucketKey!,
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

                    //Return the first condition that match.
                    if try condition.match(matchValue: matchingKey, bucketingKey: bucketKey, attributes: attributes) {
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
                Logger.d("* Treatment for \(matchingKey) in \(split.name ?? "") is: \(result.treatment)")
                return result
            } catch EvaluatorError.matcherNotFound {
                Logger.e("The matcher has not been found")
                return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.matcherNotFound,
                                          changeNumber: changeNumber)
            }
        }

        Logger.w("The SPLIT definition for '\(splitName)' has not been found")
        return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.splitNotFound)

    }
}
