//
//  Engine.swift
//  Split
//
//  Created by Natalia  Stele on 11/15/17.
//

import Foundation


public class Engine {
    
    //------------------------------------------------------------------------------------------------------------------
    public static let EVALUATION_RESULT_TREATMENT: String = "treatment"
    public static let EVALUATION_RESULT_LABEL: String = "label"
    internal var splitClient: SplitClient?
    //------------------------------------------------------------------------------------------------------------------
    public static let shared: Engine = {
        
        let instance = Engine();
        return instance;
    }()
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatment(matchingKey: String?, bucketingKey: String?, split: Split?, atributtes: [String:Any]?) throws -> [String: String] {
        
        var bucketKey: String?
        var inRollOut: Bool = false
        var result: [String: String] = [:]
        
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
                    
                    let bucket: Int = Splitter.shared.getBucket(seed: (split?.seed)!, key: bucketKey!, algo: (split?.algo!)!)
                    
                    if bucket >= trafficAllocation {
                        
                        result[Engine.EVALUATION_RESULT_TREATMENT] = split?.defaultTreatment
                        result[Engine.EVALUATION_RESULT_LABEL] = ImpressionsConstants.NOT_IN_SPLIT

                        return result
                        
                    }
                    
                    inRollOut = true
                    
                }
            }
            
            //Return the first condition that match.
            if try condition.match(matchValue: matchingKey, bucketingKey: bucketKey, atributtes: atributtes) {
                
                var bucketKey: String? = bucketingKey
                
                if  bucketKey == nil {
                    bucketKey = matchingKey
                }
                let key: Key = Key(matchingKey: matchingKey!, bucketingKey: bucketKey)

                result[Engine.EVALUATION_RESULT_TREATMENT] = Splitter.shared.getTreatment(key: key, seed: (split?.seed)!, atributtes: atributtes, partions: condition.partitions, algo: (split?.algo ?? Splitter.ALGO_LEGACY)!)
                
                result[Engine.EVALUATION_RESULT_LABEL] = condition.label
                return result
            }
            
        }
        
        return result
    }
    //------------------------------------------------------------------------------------------------------------------

}
