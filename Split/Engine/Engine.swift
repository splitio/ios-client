//
//  Engine.swift
//  Split
//
//  Created by Natalia  Stele on 11/15/17.
//

import Foundation

class Engine {
    
    static let EVALUATION_RESULT_TREATMENT: String = "treatment"
    static let EVALUATION_RESULT_LABEL: String = "label"
    static let EVALUATION_RESULT_SPLIT_VERSION: String = "splitChangeNumber"
    internal var splitClient: SplitClient?
    private var splitter: SplitterProtocol
    
    static let shared: Engine = {
        let instance = Engine();
        return instance;
    }()
    
    init(splitter: SplitterProtocol = Splitter.shared){
        self.splitter = splitter
    }
    
    func getTreatment(matchingKey: String?, bucketingKey: String?, split: Split?, attributes: [String:Any]?) throws -> [String: String] {
        
        var bucketKey: String?
        var inRollOut: Bool = false
        var result: [String: String] = [:]
        var splitAlgo: Algorithm = Algorithm.legacy
            
        if let rawAlgo = split?.algo,  let algo = Algorithm.init(rawValue: rawAlgo) {
            splitAlgo = algo
        }
        
        if bucketingKey == nil || bucketingKey == "" {
            bucketKey = matchingKey
        } else {
            bucketKey = bucketingKey
        }
        
        let conditions: [Condition] = (split?.conditions)!
        for condition in conditions {
            condition.client = self.splitClient
            if (!inRollOut && condition.conditionType == ConditionType.Rollout) {
                if let trafficAllocation = split?.trafficAllocation, trafficAllocation < 100  {
                    let bucket: Int = splitter.getBucket(seed: (split?.seed)!, key: bucketKey!, algo: splitAlgo)
                    if bucket > trafficAllocation {
                        result[Engine.EVALUATION_RESULT_TREATMENT] = split?.defaultTreatment
                        result[Engine.EVALUATION_RESULT_LABEL] = ImpressionsConstants.NOT_IN_SPLIT

                        return result
                    }
                    inRollOut = true
                }
            }
            
            //Return the first condition that match.
            if try condition.match(matchValue: matchingKey, bucketingKey: bucketKey, attributes: attributes) {
                var bucketKey: String? = bucketingKey
                
                if  bucketKey == nil {
                    bucketKey = matchingKey
                }
                let key: Key = Key(matchingKey: matchingKey!, bucketingKey: bucketKey)
                result[Engine.EVALUATION_RESULT_TREATMENT] = splitter.getTreatment(key: key, seed: (split?.seed)!, attributes: attributes, partions: condition.partitions, algo: splitAlgo)
                result[Engine.EVALUATION_RESULT_LABEL] = condition.label
                return result
            }
        }
        return result
    }
}
