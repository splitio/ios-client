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
    
    public init(_ json: JSON) {
        self.conditionType = ConditionType.enumFromString(string: json["conditionType"].stringValue)
        self.matcherGroup = MatcherGroup(json["matcherGroup"])
        self.partitions = json["partitions"].array?.map { (json: JSON) -> Partition in
            return Partition(json)
        }
        self.label = json["label"].string
    }
    
    func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String:Any]?) -> Bool {
        
        if let matcherG = self.matcherGroup, let matchers = matcherG.matchers {
            
            for matcher in matchers {
                
                let matcherEvaluator = matcher.getMatcher()
                
                if matcherEvaluator.match(matchValue: matchValue, bucketingKey: bucketingKey, atributtes: atributtes) == false {
                    
                    return false
                    
                }
                
            }
            
            return true
        }
        
        return false
    }
    
}
