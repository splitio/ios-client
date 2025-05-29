//
//  KeyImpression.swift
//  Split
//
//  Created by Javier Avrudsky on 05-Jul-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
// Data structure to replace old Impression
struct KeyImpression: Codable {
    var storageId: String?
    var featureName: String?
    var keyName: String
    var bucketingKey: String?
    var treatment: String
    var label: String?
    var time: Int64
    var changeNumber: Int64?
    var previousTime: Int64?
    var properties: String?

    init(
        featureName: String?,
        keyName: String,
        bucketingKey: String? = nil,
        treatment: String,
        label: String?,
        time: Int64,
        changeNumber: Int64?,
        previousTime: Int64? = nil,
        storageId: String? = nil,
        properties: String? = nil) {
        self.storageId = storageId
        self.featureName = featureName
        self.keyName = keyName
        self.bucketingKey = bucketingKey
        self.treatment = treatment
        self.label = label
        self.time = time
        self.changeNumber = changeNumber
        self.previousTime = previousTime
        self.properties = properties
    }

    enum CodingKeys: String, CodingKey {
        case keyName = "k"
        case treatment = "t"
        case time = "m"
        case changeNumber = "c"
        case label = "r"
        case bucketingKey = "b"
        case previousTime = "pt"
        case properties
    }

    func withPreviousTime(_ time: Int64?) -> KeyImpression {
        return KeyImpression(
            featureName: featureName,
            keyName: keyName,
            bucketingKey: bucketingKey,
            treatment: treatment,
            label: label,
            time: self.time,
            changeNumber: changeNumber,
            previousTime: time,
            storageId: storageId,
            properties: properties)
    }

    func toImpression() -> Impression {
        let impression = Impression()
        impression.feature = featureName
        impression.keyName = keyName
        impression.bucketingKey = bucketingKey
        impression.label = label
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = time
        impression.properties = properties
        return impression
    }
}

struct DeprecatedImpression: Codable {
    var storageId: String?
    var featureName: String?
    var keyName: String
    var bucketingKey: String?
    var treatment: String
    var label: String?
    var time: Int64
    var changeNumber: Int64?
    var previousTime: Int64?

    enum CodingKeys: String, CodingKey {
        case keyName
        case treatment
        case time
        case changeNumber
        case label
        case bucketingKey
    }

    func toKeyImpression() -> KeyImpression {
        return KeyImpression(
            featureName: featureName,
            keyName: keyName,
            bucketingKey: bucketingKey,
            treatment: treatment,
            label: label,
            time: time,
            changeNumber: changeNumber,
            previousTime: previousTime,
            storageId: storageId)
    }
}
