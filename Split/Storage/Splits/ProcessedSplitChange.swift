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

protocol SplitChangeProcessor {
    func process(_ splitChange: SplitChange) -> ProcessedSplitChange
}

class DefaultSplitChangeProcessor: SplitChangeProcessor {
    func process(_ splitChange: SplitChange) -> ProcessedSplitChange {
        let active = splitChange.splits.filter { $0.status == .active }
        let archived = splitChange.splits.filter { $0.status == .archived }
        return ProcessedSplitChange(activeSplits: active, archivedSplits: archived,
                                    changeNumber: splitChange.till, updateTimestamp: Date().unixTimestamp())
    }
}
