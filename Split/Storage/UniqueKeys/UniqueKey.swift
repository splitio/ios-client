//
//  UniqueKeys.swift
//  Split
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

struct UniqueKey {
    let storageId: String?
    let userKey: String
    let features: [String]

    init(storageId: String? = nil, userKey: String, features: [String]) {
        self.storageId = storageId
        self.userKey = userKey
        self.features = features
    }

    enum CodingKeys: String, CodingKey {
        case key = "k"
        case features = "fs"
    }
}
