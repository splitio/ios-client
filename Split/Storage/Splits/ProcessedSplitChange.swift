//
//  ProcessedSplitChange.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct ProcessedSplitChange {
    let activeSplits: [Split]
    let archivedSplits: [Split]
    let changeNumber: Int64
    let updateTimestamp: Int64
}
