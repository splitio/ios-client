//
//  Impression.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
public typealias SplitImpression = Impression

@objc public class Impression: NSObject, Codable {
    var storageId: String?
    @objc public var feature: String?
    @objc public var keyName: String?
    @objc public var treatment: String?
    public var time: Int64?
    // Added cause Int couldn't be null in Objc
    @objc public var timestamp: NSNumber? {
        return time as NSNumber?
    }
    public var changeNumber: Int64?
    @objc public var changeNum: NSNumber? {
        return changeNumber as NSNumber?
    }
    @objc public var label: String?
    @objc public var bucketingKey: String?
    @objc public var attributes: [String: Any]?

    var previousTime: Int64?

    enum CodingKeys: String, CodingKey {
        case keyName
        case treatment
        case time
        case changeNumber
        case label
        case bucketingKey
    }
}
