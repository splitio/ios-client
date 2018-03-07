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

        if let splitTreated: Split = splitFetcher?.fetch(splitName: split), splitTreated.status != Status.Archived {
            
            if let killed = splitTreated.killed, killed {
                createImpression(label: ImpressionsConstants.KILLED, changeNumber: splitTreated.changeNumber!, treatment: splitTreated.defaultTreatment!, splitName: splitTreated.name!)
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
                
                Logger.d("* Treatment for \(key) in \(String(describing: splitTreated.name)) is: \(String(describing: treatment))")
                
                result[Engine.EVALUATION_RESULT_TREATMENT] = treatment
                
                var resultLabel: String?
                
                if let label = impressionLabel {
                    
                    resultLabel = label
                    
                } else {
                    
                    resultLabel = " "

                }

                createImpression(label: resultLabel!, changeNumber: splitTreated.changeNumber!, treatment: treatment!, splitName: splitTreated.name!)

                result[Engine.EVALUATION_RESULT_LABEL] = impressions

                
            }
            
        } else {
            
            Logger.w("The SPLIT definition for '\(split)' has not been found");
            result[Engine.EVALUATION_RESULT_TREATMENT] = SplitConstants.CONTROL
            createImpression(label: ImpressionsConstants.SPLIT_NOT_FOUND, changeNumber: nil, treatment: SplitConstants.CONTROL, splitName: split)
            result[Engine.EVALUATION_RESULT_LABEL] = impressions
    
        }
        
        return result
        
    }
    //------------------------------------------------------------------------------------------------------------------
    func createImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String) {
        
        let impression: ImpressionDTO = ImpressionDTO()
        impression.keyName = splitClient?.key.matchingKey
        
        impression.bucketingKey = (splitClient?.shouldSendBucketingKey)! ? splitClient?.key.bucketingKey : nil
        impression.label = label
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Int64(Date().timeIntervalSince1970 * 1000)
        ImpressionManager.shared.appendImpressions(impression: impression, splitName: splitName)
    }
}
