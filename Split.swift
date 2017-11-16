//
//  Split.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Split: NSObject, SplitBase {
    
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
        
        self.name = json["name"].string
        self.seed = json["seed"].int
        self.status = Status.enumFromString(string: json["status"].stringValue)
        self.killed = json["killed"].bool
        self.defaultTreatment = json["defaultTreatment"].string
        self.conditions = json["conditions"].arrayValue.map { (json: JSON) -> Condition in
            return Condition(json)
        }
        self.trafficTypeName = json["trafficTypeName"].string
        self.changeNumber = json["changeNumber"].int64
        self.trafficAllocation = json["trafficAllocation"].int
        self.trafficAllocationSeed = json["trafficAllocationSeed"].int
        self.algo = json["algo"].int
    }
}
