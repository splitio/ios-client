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
    var splitClient: InternalSplitClient?  {
        
        didSet {
            
            self.splitFetcher = self.splitClient?.splitFetcher
            self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
            
        }
    }
    
    static let shared: Evaluator = {
        
        let instance = Evaluator()
        return instance;
    }()
    
    init(splitClient: InternalSplitClient? = nil) {
        
        self.splitClient = splitClient
        self.splitFetcher = self.splitClient?.splitFetcher
        self.mySegmentsFetcher = self.splitClient?.mySegmentsFetcher
        self.impressions = []
    }
    
    func evalTreatment(key: String, bucketingKey: String? , split: String, attributes:[String:Any]?) throws -> EvaluationResult  {

        if let splitTreated: Split = splitFetcher?.fetch(splitName: split), splitTreated.status != Status.Archived {
            
            if let killed = splitTreated.killed, killed {
                let treatment = splitTreated.defaultTreatment ?? SplitConstants.CONTROL
                let configurations = splitTreated.configurations?[treatment]
                return EvaluationResult(treatment: treatment,
                                        label: ImpressionsConstants.KILLED,
                                        splitVersion: (splitTreated.changeNumber ?? -1),
                                        configurations: configurations)
            }
            
            var result: EvaluationResult!
            let engine = Engine.shared
            engine.splitClient = self.splitClient
            do {
                result = try engine.getTreatment(matchingKey: key, bucketingKey: bucketingKey, split: splitTreated, attributes: attributes)
                result.splitVersion = splitTreated.changeNumber
                Logger.d("* Treatment for \(key) in \(splitTreated.name ?? "") is: \(result.treatment)")
            } catch EngineError.MatcherNotFound {
                Logger.e("The matcher has not been found");
                result = EvaluationResult(treatment: SplitConstants.CONTROL,
                                          label: ImpressionsConstants.MATCHER_NOT_FOUND,
                                          splitVersion: splitTreated.changeNumber)
            }
            return result
        }
        
        Logger.w("The SPLIT definition for '\(split)' has not been found");
        return EvaluationResult(treatment: SplitConstants.CONTROL, label: ImpressionsConstants.SPLIT_NOT_FOUND)
        
    }
}
