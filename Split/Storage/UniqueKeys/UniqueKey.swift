//
//  UniqueKeys.swift
//  Split
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

struct UniqueKey {
    let storageId: String
    let userKey: String
    let features: [String]
    var sendAttemptCount: Int16 = 0

    enum CodingKeys: String, CodingKey {
        case key = "k"
        case features = "fs"
    }
}
