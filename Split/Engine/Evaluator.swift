//
//  Evaluator.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

class Evaluator {
    var impressions: [Impression]
    var splitFetcher: SplitFetcher?
    var mySegmentsFetcher: MySegmentsFetcher?
    var splitClient: DefaultSplitClient?  {
        
        didSet {
            
            self.splitFetcher = self.splitClient?.splitFetcher
            self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
            
        }
    }
    
    static let shared: Evaluator = {
        
        let instance = Evaluator()
        return instance;
    }()
    
    init(splitClient: DefaultSplitClient? = nil) {
        
        self.splitClient = splitClient
        self.splitFetcher = self.splitClient?.splitFetcher
        self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
        self.impressions = []
    }
    
    func evalTreatment(key: String, bucketingKey: String? , split: String, attributes:[String:Any]?) throws -> EvaluationResult?  {

        var result: EvaluationResult?
        
        if let splitTreated: Split = splitFetcher?.fetch(splitName: split), splitTreated.status != Status.Archived {
            
            if let killed = splitTreated.killed, killed {
                return EvaluationResult(treatment: splitTreated.defaultTreatment ?? SplitConstants.CONTROL,
                                        label: ImpressionsConstants.KILLED,
                                        splitVersion: (splitTreated.changeNumber ?? -1))
            } else {
 
                let engine = Engine.shared
                engine.splitClient = self.splitClient
                do {
                    var evaluationResult = try engine.getTreatment(matchingKey: key, bucketingKey: bucketingKey, split: splitTreated, attributes: attributes)
                    
                    if evaluationResult.treatment == SplitConstants.CONTROL {
                        treatment = splitTreated.defaultTreatment!
                        impressionLabel = ImpressionsConstants.NO_CONDITION_MATCHED
                        
                    }
                    //var treatment: String? = evaluationResult.treatment
                    var impressionLabel: String? = evaluationResult.label
                    let impressionSplitVersion: Int64? = splitTreated.changeNumber!

        
                    
                    Logger.d("* Treatment for \(key) in \(String(describing: splitTreated.name)) is: \(String(describing: treatment))")
                    
                    result[Engine.kEvaluationResult] = treatment
                    result[Engine.kEvaluationResultSplitVersion] = impressionSplitVersion
                    
                    if let label = impressionLabel {
                        result[Engine.kEvaluationResultLabel] = label
                    } else {
                        result[Engine.kEvaluationResultLabel] = " "
                    }
                } catch EngineError.MatcherNotFound {
                    Logger.e("The matcher has not been found");
                    result = EvaluationResult(treatment: SplitConstants.CONTROL,
                                              label: ImpressionsConstants.MATCHER_NOT_FOUND,
                                              splitVersion: splitTreated.changeNumber ?? -1)
                }
                
            }
            
        } else {
            Logger.w("The SPLIT definition for '\(split)' has not been found");
            result = EvaluationResult(treatment: SplitConstants.CONTROL, label: ImpressionsConstants.SPLIT_NOT_FOUND)
        }
        
        return result
        
    }
}
