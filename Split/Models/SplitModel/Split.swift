//  Created by Brian Sztamfater on 28/9/17.

import Foundation

// The JSON is -partially- parsed at startup to improve SDK ready times (for example "conditions" are left out).
// After parsing just the strictly necesary stuff, it saves the complete JSON to finish parsing later.
// Once .sdkReady is fired, it concurrently finishes parsing the rest.

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
    var prerequisites: [Prerequisite]?

    var json: String = ""

    var isCompletelyParsed = true

    init(name: String, trafficType: String, status: Status, sets: Set<String>?, json: String, killed: Bool = false, impressionsDisabled: Bool = false) {
        self.name = name
        self.trafficTypeName = trafficType
        self.status = status
        self.sets = sets
        self.json = json
        self.killed = killed
        self.isCompletelyParsed = false
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
        case prerequisites
    }
}

@objc public class Prerequisite: NSObject, Codable {
    var n: String
    var ts: [String]
    
    #if DEBUG
    init(n: String, ts: [String]) {
        self.n = n
        self.ts = ts
    }
    #endif
}
