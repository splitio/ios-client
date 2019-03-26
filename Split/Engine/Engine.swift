//
//  Engine.swift
//  Split
//
//  Created by Natalia  Stele on 11/15/17.
//

import Foundation

struct EvaluationResult {
    var treatment: String
    var label: String?
    var splitVersion: Int64?
    var configurations: String?
    
    init(treatment: String, label: String? = nil, splitVersion: Int64? = nil, configurations: String? = nil){
        self.treatment = treatment
        self.label = label
        self.splitVersion = splitVersion
        self.configurations = configurations
    }
}

class Engine {

    internal var splitClient: DefaultSplitClient?
    private var splitter: SplitterProtocol
    
    static let shared: Engine = {
        let instance = Engine();
        return instance;
    }()
    
    init(splitter: SplitterProtocol = Splitter.shared){
        self.splitter = splitter
    }
    
    func getTreatment(matchingKey: String?, bucketingKey: String?, split: Split, attributes: [String:Any]?) throws -> EvaluationResult {
        var bucketKey: String?
        var inRollOut: Bool = false
        var splitAlgo: Algorithm = Algorithm.legacy
        let defaultTreatment  = split.defaultTreatment ?? SplitConstants.CONTROL
            
        if let rawAlgo = split.algo,  let algo = Algorithm.init(rawValue: rawAlgo) {
            splitAlgo = algo
        }
        
        bucketKey = !(bucketingKey ?? "").isEmpty() ? bucketingKey : matchingKey
        
        guard let conditions: [Condition] = split.conditions else {
            return EvaluationResult(treatment: SplitConstants.CONTROL)
        }
        
        guard let seed = split.seed else {
            return EvaluationResult(treatment: SplitConstants.CONTROL)
        }
        
        for condition in conditions {
            condition.client = self.splitClient
            if (!inRollOut && condition.conditionType == ConditionType.Rollout) {
                if let trafficAllocation = split.trafficAllocation, trafficAllocation < 100  {
                    let bucket: Int64 = splitter.getBucket(seed: seed, key: bucketKey!, algo: splitAlgo)
                    if bucket > trafficAllocation {
                        return EvaluationResult(treatment: defaultTreatment, label: ImpressionsConstants.NOT_IN_SPLIT)
                    }
                    inRollOut = true
                }
            }
            
            //Return the first condition that match.
            if try condition.match(matchValue: matchingKey, bucketingKey: bucketKey, attributes: attributes) {
                let key: Key = Key(matchingKey: matchingKey!, bucketingKey: bucketKey)
                let treatment = splitter.getTreatment(key: key, seed: seed, attributes: attributes, partions: condition.partitions, algo: splitAlgo)
                return EvaluationResult(treatment: treatment, label: condition.label)
            }
        }
        return EvaluationResult(treatment: defaultTreatment)
    }
}
