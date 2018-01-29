//
//  Condition.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Condition: NSObject {
    
    public var conditionType: ConditionType?
    public var matcherGroup: MatcherGroup?
    public var partitions: [Partition]?
    public var label: String?
    public var client: SplitClient?
    
    public init(_ json: JSON) {
        self.conditionType = ConditionType.enumFromString(string: json["conditionType"].stringValue)
        self.matcherGroup = MatcherGroup(json["matcherGroup"])
        self.partitions = json["partitions"].array?.map { (json: JSON) -> Partition in
            return Partition(json)
        }
        self.label = json["label"].string
    }
    
    func match(matchValue: Any?, bucketingKey: String?, atributtes: [String:Any]?) throws -> Bool {
        
        if let matcherG = self.matcherGroup, let matchers = matcherG.matchers {
            
            var results: [Bool] = []
            
            for matcher in matchers {
                
                matcher.client = self.client

                let matcherEvaluator = matcher.getMatcher()
                var result: Bool = false

                if matcherEvaluator.getMatcherType() != MatcherType.Dependency {
                    
                    // scenario 1: no attr in matcher
                    // e.g. if user is in segment all then split 100:on
                    if !matcherEvaluator.matcherHasAttribute() {
                        
                        //let matcherEv = matcherEvaluator2(matcher: matcherEvaluator)
                        result = matcherEvaluator.evaluate(matchValue: matchValue, bucketingKey: nil, atributtes: nil)
                
                    } else {
                       
                        // scenario 2: attribute provided but no attribute value provided. Matcher does not match
                        // e.g. if user.age is >= 10 then split 100:on
                        let att = matcherEvaluator.getAttribute()!
                        if atributtes == nil || atributtes![att] == nil {
                            
                            result = false
                
                        } else {
                            // instead of using the user id, we use the attribute value for evaluation
                            
                            result = matcherEvaluator.evaluate(matchValue: atributtes![att], bucketingKey: nil, atributtes: nil)
                        }
                        
                    }
                    
                } else {
                    
                    if matcherEvaluator.getMatcherType() == MatcherType.Dependency {
                        
                           result = matcherEvaluator.evaluate(matchValue: matchValue, bucketingKey: bucketingKey, atributtes: atributtes)
                        
                        
                    }
                 
                }
                
                let lastEvaluation = matcherEvaluator.isNegate() ? !result : result
                results.append(lastEvaluation)
            }
            
            
            switch matcherG.matcherCombiner {
                
                case .And?:
                    return (matcherG.matcherCombiner?.combineAndResults(partialResults: results))!
  
                case .none:
                    return (matcherG.matcherCombiner?.combineAndResults(partialResults: results))!
            }
            
        }
        
        return false

    }
    
}
