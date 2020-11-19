//
//  SplitsSnapshot.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct SplitsSnapshot {
    let changeNumber: Int64
    let splits: [Split]
    let updateTimestamp: Int64
    let splitsFilterQueryString: String
}
