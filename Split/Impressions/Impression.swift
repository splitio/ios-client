//
//  Impression.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
public typealias SplitImpression = Impression

public struct Impression: Codable {

    public var keyName: String?
    public var treatment: String?
    public var time: Int64?
    public var changeNumber: Int64?
    public var label: String?
    public var bucketingKey: String?
    public var attributes: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case keyName
        case treatment
        case time
        case changeNumber
        case label
        case bucketingKey
    }
}
