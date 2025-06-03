//  Created by Brian Sztamfater on 28/9/17.

import Foundation

// The JSON is -partially- parsed at startup to improve SDK ready times (for example "conditions" are left out).
// After parsing just the strictly necesary stuff, it saves the complete JSON to finish parsing later.
// Once .sdkReady is fired, it concurrently finishes parsing the rest (on SplitStorage.get())

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

    // SDK loading optimization
    var json: String = ""
    var isCompletelyParsed = false

    init(name: String, trafficType: String, status: Status, sets: Set<String>?, json: String, killed: Bool = false, impressionsDisabled: Bool = false) {
        self.name = name
        self.trafficTypeName = trafficType
        self.status = status
        self.sets = sets
        self.json = json
        self.killed = killed
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
    @objc public var flagName: String
    @objc public var treatments: [String]
    
    enum CodingKeys: String, CodingKey {
        case flagName = "n"
        case treatments = "ts"
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.flagName = try container.decodeIfPresent(String.self, forKey: .flagName) ?? ""
        self.treatments = try container.decodeIfPresent([String].self, forKey: .treatments) ?? []
    }
    
    #if DEBUG
    init(flagName: String, treatments: [String]) {
        self.flagName = flagName
        self.treatments = treatments
    }
    #endif
}
