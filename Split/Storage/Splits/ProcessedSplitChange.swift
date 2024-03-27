//
//  ProcessedSplitChange.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct ProcessedSplitChange {
    let activeSplits: [SplitDTO]
    let archivedSplits: [SplitDTO]
    let changeNumber: Int64
    let updateTimestamp: Int64
}

protocol SplitChangeProcessor {
    func process(_ splitChange: SplitChange) -> ProcessedSplitChange
}

class DefaultSplitChangeProcessor: SplitChangeProcessor {
    let filterSet: Set<String>?

    init(filterBySet: SplitFilter?) {
        filterSet = filterBySet?.values.asSet()
    }

    func process(_ splitChange: SplitChange) -> ProcessedSplitChange {

        var active = [SplitDTO]()
        var archived = [SplitDTO]()
        if let filterSet = self.filterSet {
            active = splitChange.splits.filter {
                $0.status == .active
                && ($0.sets?.count ?? -1) > 0
                && !(filterSet.isDisjoint(with: $0.sets ?? []))
            }

            archived = splitChange.splits.filter {
                $0.status == .archived
                || ($0.sets?.count ?? 0) == 0
                || filterSet.isDisjoint(with: $0.sets ?? [])
            }
        } else {
            active = splitChange.splits.filter { $0.status == .active }
            archived = splitChange.splits.filter { $0.status == .archived }
        }

        return ProcessedSplitChange(activeSplits: active,
                                    archivedSplits: archived,
                                    changeNumber: splitChange.till, updateTimestamp: Date().unixTimestamp())
    }
}
