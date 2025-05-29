//
//  Split.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

typealias Split = SplitDTO

class SplitDTO: NSObject, SplitBase, Codable {
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
    var sets: Set<String>?
    var impressionsDisabled: Bool?

    var json: String = ""

    var isParsed = true

    init(
        name: String,
        trafficType: String,
        status: Status,
        sets: Set<String>?,
        json: String,
        killed: Bool = false,
        impressionsDisabled: Bool = false) {
        self.name = name
        self.trafficTypeName = trafficType
        self.status = status
        self.sets = sets
        self.json = json
        self.killed = killed
        self.isParsed = false
        self.impressionsDisabled = impressionsDisabled
    }

    enum CodingKeys: String, CodingKey {
        case name
        case seed
        case status
        case killed
        case defaultTreatment
        case conditions
        case trafficTypeName
        case changeNumber
        case trafficAllocation
        case trafficAllocationSeed
        case algo
        case configurations
        case sets
        case impressionsDisabled
    }
}
