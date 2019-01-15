//
//  Split.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class Split: NSObject, SplitBase, Codable, Validatable {
    
    typealias Entity = Split
    
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
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
    
}
