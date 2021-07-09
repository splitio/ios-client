//
//  PersistentImpressionsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-06-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentImpressionsCountStorageStub: PersistentImpressionsCountStorage {


    var storedImpressions = [String: ImpressionsCountPerFeature]()
    var impressionsStatus = [String: Int32]()

    func delete(_ impressions: [ImpressionsCountPerFeature]) {
        let ids = impressions.compactMap { $0.storageId }
        for uid in ids {
            storedImpressions.removeValue(forKey: uid)
            impressionsStatus.removeValue(forKey: uid)
        }
    }

    func pop(count: Int) -> [ImpressionsCountPerFeature] {
        let deleted = impressionsStatus.filter { $0.value == StorageRecordStatus.deleted }.keys
        let poped = Array(storedImpressions.values.filter { !deleted.contains($0.storageId ?? "") }.prefix(count))
        for impression in poped {
            impressionsStatus[impression.storageId ?? ""] = StorageRecordStatus.deleted
        }
        return poped
    }

    func push(count: ImpressionsCountPerFeature) {
        if let eId = count.storageId {
            storedImpressions[eId] = count
            impressionsStatus[eId] = StorageRecordStatus.active
        }
    }

    func pushMany(counts: [ImpressionsCountPerFeature]) {
        for count in counts {
            if let eId = count.storageId {
                storedImpressions[eId] = count
                impressionsStatus[eId] = StorageRecordStatus.active
            }
        }
    }

    func setActive(_ counts: [ImpressionsCountPerFeature]) {
        for count in counts {
            if let eId = count.storageId {
                impressionsStatus[eId] = StorageRecordStatus.active
            }
        }
    }
}
