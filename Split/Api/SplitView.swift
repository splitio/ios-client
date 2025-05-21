//
//  SplitView.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

public class SplitView: NSObject, Codable {

    @objc public var name: String?
    @objc public var trafficType: String?
    @objc public var defaultTreatment: String?
    public var killed: Bool?
    @objc public var isKilled: Bool {
        return killed ?? false
    }
    @objc public var treatments: [String]?
    @objc public var sets: [String]?
    public var changeNumber: Int64?

    @objc public var changeNum: NSNumber? {
        return changeNumber as NSNumber?
    }
    @objc public var configs: [String: String]?

    @objc public var impressionsDisabled: Bool = false
}


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
var preTrequisites: [String: [String]]?
