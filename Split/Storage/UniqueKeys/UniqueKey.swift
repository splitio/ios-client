//
//  UniqueKeys.swift
//  Split
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

struct UniqueKey {
    let userKey: String
    let features: [String]

    enum CodingKeys: String, CodingKey {
        case key = "k"
        case features = "fs"
    }
}
