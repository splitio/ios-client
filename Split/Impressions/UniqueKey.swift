//
//  UniqueKey.swift
//  Split
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

// Codable for testing
class UniqueKey: Codable {
    var storageId: String?
    var userKey: String
    var features: Set<String>

    init(storageId: String? = nil, userKey: String, features: Set<String>) {
        self.storageId = storageId
        self.userKey = userKey
        self.features = features
    }

    enum CodingKeys: String, CodingKey {
        case userKey = "k"
        case features = "fs"
    }
}
