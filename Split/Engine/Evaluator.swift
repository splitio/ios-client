//
//  Evaluator.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

public class Evaluator {
    
    //------------------------------------------------------------------------------------------------------------------
    public var impressions: [Impression] 
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
    public func evalTreatment(key: String, bucketingKey: String? , split: String, attributes:[String:Any]?) throws -> [String:Any]?  {
        
        var result: [String:Any] = [:]

        if let splitTreated: Split = splitFetcher?.fetch(splitName: split), splitTreated.status != Status.Archived {
            
            if let killed = splitTreated.killed, killed {
                result[Engine.EVALUATION_RESULT_TREATMENT] = splitTreated.defaultTreatment!
                result[Engine.EVALUATION_RESULT_LABEL] = ImpressionsConstants.KILLED
                result[Engine.EVALUATION_RESULT_SPLIT_VERSION] = splitTreated.changeNumber!
            } else {
 
                let engine = Engine.shared
                engine.splitClient = self.splitClient
                do {
                    let evaluationResult = try engine.getTreatment(matchingKey: key, bucketingKey: bucketingKey, split: splitTreated, attributes: attributes)
                    
                    var treatment: String? = evaluationResult[Engine.EVALUATION_RESULT_TREATMENT]
                    var impressionLabel: String? = evaluationResult[Engine.EVALUATION_RESULT_LABEL]
                    let impressionSplitVersion: Int64? = splitTreated.changeNumber!
                    
                    if treatment == nil {
                        
                        treatment = splitTreated.defaultTreatment!
                        impressionLabel = ImpressionsConstants.NO_CONDITION_MATCHED
                        
                    }
                    
                    Logger.d("* Treatment for \(key) in \(String(describing: splitTreated.name)) is: \(String(describing: treatment))")
                    
                    result[Engine.EVALUATION_RESULT_TREATMENT] = treatment
                    result[Engine.EVALUATION_RESULT_SPLIT_VERSION] = impressionSplitVersion
                    
                    if let label = impressionLabel {
                        result[Engine.EVALUATION_RESULT_LABEL] = label
                    } else {
                        result[Engine.EVALUATION_RESULT_LABEL] = " "
                    }
                } catch EngineError.MatcherNotFound {
                    Logger.e("The matcher has not been found");
                    result[Engine.EVALUATION_RESULT_TREATMENT] = SplitConstants.CONTROL
                    result[Engine.EVALUATION_RESULT_LABEL] = ImpressionsConstants.MATCHER_NOT_FOUND
                    result[Engine.EVALUATION_RESULT_SPLIT_VERSION] = splitTreated.changeNumber!
                }
                
            }
            
        } else {
            Logger.w("The SPLIT definition for '\(split)' has not been found");
            result[Engine.EVALUATION_RESULT_TREATMENT] = SplitConstants.CONTROL
            result[Engine.EVALUATION_RESULT_LABEL] = ImpressionsConstants.SPLIT_NOT_FOUND
            result[Engine.EVALUATION_RESULT_SPLIT_VERSION] = nil
        }
        
        return result
        
    }
}
