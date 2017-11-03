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
    
    var conditionType: ConditionType?
    var matcherGroup: MatcherGroup?
    var partitions: [Partition]?
    var label: String?
    
    public init(_ json: JSON) {
        self.conditionType = ConditionType.enumFromString(string: json["conditionType"].stringValue)
        self.matcherGroup = MatcherGroup(json["matcherGroup"])
        self.partitions = json["partitions"].array?.map { (json: JSON) -> Partition in
            return Partition(json)
        }
        self.label = json["label"].string
    }
}
