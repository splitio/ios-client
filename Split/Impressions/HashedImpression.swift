//
//  HashedImpression.swift
//  Split
//
//  Created by Javier Avrudsky on 17-May-2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class HashedImpression {
    let impressionHash: Int64
    let time: Int64
    let createdAt: Int64

    init(impressionHash: Int64, time: Int64, createdAt: Int64) {
        self.impressionHash = impressionHash
        self.time = time
        self.createdAt = createdAt
    }
}
