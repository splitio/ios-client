//
//  Evaluator.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

public class Evaluator {
    
    //------------------------------------------------------------------------------------------------------------------
    internal var splitFetcher: SplitFetcher?
    internal var mySegmentsFetcher: MySegmentsFetcher?
    //------------------------------------------------------------------------------------------------------------------
    public static let shared: Evaluator = {
        
        let instance = Evaluator()
        return instance;
    }()
    //------------------------------------------------------------------------------------------------------------------
    public init(splitFetcher: SplitFetcher? = nil, mySegmentsFetcher: MySegmentsFetcher? = nil) {
        
        self.splitFetcher = splitFetcher
        self.mySegmentsFetcher = mySegmentsFetcher
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func evalTreatment(key: String, bucketingKey: String? , split: String, atributtes:[String:Any]?) -> [String:Any]?  {
        
        var result: [String:Any] = [:]
        var impressions: [String: Any] = [:]

        //TODO: Use the cache here
        if let splitTreated: Split = splitFetcher?.fetch(splitName: split) {
            
            if let killed = splitTreated.killed, killed {
                
                impressions["label"] = "KILLED"
                impressions["changeNumber"] = splitTreated.changeNumber
                result[Engine.EVALUATION_RESULT_TREATMENT] = splitTreated.defaultTreatment!
                result[Engine.EVALUATION_RESULT_LABEL] = impressions
                
                
            } else {
                
                let evaluationResult = Engine.shared.getTreatment(matchingKey: key, bucketingKey: bucketingKey, split: splitTreated, atributtes: atributtes)
                
                var treatment: String? = evaluationResult[Engine.EVALUATION_RESULT_TREATMENT]
                var impressionLabel: String? = evaluationResult[Engine.EVALUATION_RESULT_LABEL]
                
                if treatment == nil {
                    
                    treatment = splitTreated.defaultTreatment!
                    impressionLabel = "NO_CONDITION_MATCHED"
                    
                }
                
                print("* Treatment for \(key) in \(String(describing: splitTreated.name)) is: \(String(describing: treatment))")
                
                result[Engine.EVALUATION_RESULT_TREATMENT] = treatment
                impressions["label"] = impressionLabel
                impressions["changeNumber"] = splitTreated.changeNumber
                result[Engine.EVALUATION_RESULT_LABEL] = impressions

                
            }
            
        } else {
            
            print("The SPLIT definition for '$featureName' has not been found'");
    
        }
        
        return result
        
    }
    //------------------------------------------------------------------------------------------------------------------

}
