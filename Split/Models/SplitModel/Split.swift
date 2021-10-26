//
//  Split.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

class Split: NSObject, SplitBase, Codable {
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
    var configurations: [String: String]?
}
