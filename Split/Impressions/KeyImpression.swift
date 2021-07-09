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

    init( featureName: String?,
          keyName: String,
          bucketingKey: String? = nil,
          treatment: String,
          label: String?,
          time: Int64,
          changeNumber: Int64?,
          previousTime: Int64? = nil,
          storageId: String? = nil) {

        self.storageId = storageId
        self.featureName = featureName
        self.keyName = keyName
        self.bucketingKey = bucketingKey
        self.treatment = treatment
        self.label = label
        self.time = time
        self.changeNumber = changeNumber
        self.previousTime = previousTime
    }

    enum CodingKeys: String, CodingKey {
        case keyName = "k"
        case treatment = "t"
        case time = "m"
        case changeNumber = "c"
        case label = "r"
        case bucketingKey = "b"
        case previousTime = "pt"
    }

    func withPreviousTime(_ time: Int64?) -> KeyImpression {
        return KeyImpression(featureName: self.featureName,
                                 keyName: self.keyName,
                                 bucketingKey: self.bucketingKey,
                                 treatment: self.treatment,
                                 label: self.label,
                                 time: self.time,
                                 changeNumber: self.changeNumber,
                                 previousTime: time,
                                 storageId: self.storageId)
    }

    func toImpression() -> Impression {
        let impression: Impression = Impression()
        impression.feature = self.featureName
        impression.keyName = self.keyName
        impression.bucketingKey = self.bucketingKey
        impression.label = self.label
        impression.changeNumber = self.changeNumber
        impression.treatment = self.treatment
        impression.time = self.time
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
        return KeyImpression(featureName: self.featureName,
                             keyName: self.keyName,
                             bucketingKey: self.bucketingKey,
                             treatment: self.treatment,
                             label: self.label,
                             time: self.time,
                             changeNumber: self.changeNumber,
                             previousTime: self.previousTime,
                             storageId: self.storageId)
    }
}
