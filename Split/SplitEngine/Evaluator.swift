//
//  Evaluator.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

public class Evaluator {
    
    //------------------------------------------------------------------------------------------------------------------
    public var impressions: [ImpressionDTO] 
    internal var splitFetcher: SplitFetcher?
    internal var mySegmentsFetcher: MySegmentsFetcher?
    internal var splitClient: SplitClient?  {
        
        didSet {
            
            self.splitFetcher = self.splitClient?.splitFetcher
            self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
            
        }
    }
    //------------------------------------------------------------------------------------------------------------------
    public static let shared: Evaluator = {
        
        let instance = Evaluator()
        return instance;
    }()
    //------------------------------------------------------------------------------------------------------------------
    public init(splitClient: SplitClient? = nil) {
        
        self.splitClient = splitClient
        self.splitFetcher = self.splitClient?.splitFetcher
        self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
        self.impressions = []
    }
    //------------------------------------------------------------------------------------------------------------------
    public func evalTreatment(key: String, bucketingKey: String? , split: String, atributtes:[String:Any]?) throws -> [String:Any]?  {
        
        var result: [String:Any] = [:]

        //TODO: Use the cache here
        if let splitTreated: Split = splitFetcher?.fetch(splitName: split) {
            
            if let killed = splitTreated.killed, killed {
                createImpression(label: "KILLED", changeNumber: splitTreated.changeNumber!, treatment: splitTreated.defaultTreatment!, splitName: splitTreated.name!)
                result[Engine.EVALUATION_RESULT_TREATMENT] = splitTreated.defaultTreatment!
                result[Engine.EVALUATION_RESULT_LABEL] = impressions
                
                
            } else {
 
                let engine = Engine.shared
                engine.splitClient = self.splitClient
                
                let evaluationResult = try engine.getTreatment(matchingKey: key, bucketingKey: bucketingKey, split: splitTreated, atributtes: atributtes)
                
                var treatment: String? = evaluationResult[Engine.EVALUATION_RESULT_TREATMENT]
                var impressionLabel: String? = evaluationResult[Engine.EVALUATION_RESULT_LABEL]
                
                if treatment == nil {
                    
                    treatment = splitTreated.defaultTreatment!
                    impressionLabel = ImpressionsConstants.NO_CONDITION_MATCHED
                    
                }
                
                print("* Treatment for \(key) in \(String(describing: splitTreated.name)) is: \(String(describing: treatment))")
                
                result[Engine.EVALUATION_RESULT_TREATMENT] = treatment
                createImpression(label: impressionLabel!, changeNumber: splitTreated.changeNumber!, treatment: treatment!, splitName: splitTreated.name!)

                result[Engine.EVALUATION_RESULT_LABEL] = impressions

                
            }
            
        } else {
            
            print("The SPLIT definition for '$featureName' has not been found'");
    
        }
        
        return result
        
    }
    //------------------------------------------------------------------------------------------------------------------
    func createImpression(label: String, changeNumber: Int64, treatment: String, splitName: String) {
        
        let impression: ImpressionDTO = ImpressionDTO()
        impression.keyName = splitClient?.key.matchingKey
        impression.bucketingKey = splitClient?.key.bucketingKey
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Int64(Date().timeIntervalSince1970 * 1000)
        ImpressionManager.shared.appendImpressions(impression: impression, splitName: splitName)
    }
}
