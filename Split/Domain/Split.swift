//
//  Split.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Split: NSObject {
    
    var name: String?
    var seed: Int?
    var status: Status?
    var killed: Bool?
    var defaultTreatment: String?
    var conditions: [Condition]?
    var trafficTypeName: String?
    var changeNumber: Int64?
    var trafficAllocation: Int?
    var trafficAllocationSeed: Int?
    var algo: Int?
    
    public init(_ json: JSON) {
        self.name = json["name"].stringValue
        self.seed = json["seed"].intValue
        self.status = Status.enumFromString(string: json["status"].stringValue)
        self.killed = json["killed"].boolValue
        self.defaultTreatment = json["defaultTreatment"].stringValue
        self.conditions = json["conditions"].arrayValue.map { (json: JSON) -> Condition in
            return Condition(json)
        }
        self.trafficTypeName = json["trafficTypeName"].stringValue
        self.changeNumber = json["changeNumber"].int64Value
        self.trafficAllocation = json["trafficAllocation"].intValue
        self.trafficAllocationSeed = json["trafficAllocationSeed"].intValue
        self.algo = json["algo"].intValue
    }
}
