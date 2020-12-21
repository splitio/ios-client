//
//  PersistentImpressionsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentImpressionsStorageStub: PersistentImpressionsStorage {


    var storedImpressions = [String: Impression]()
    var impressionsStatus = [String: Int32]()

    func delete(_ impressions: [Impression]) {
        let ids = impressions.compactMap { $0.storageId }
        for uid in ids {
            storedImpressions.removeValue(forKey: uid)
            impressionsStatus.removeValue(forKey: uid)
        }
    }

    func pop(count: Int) -> [Impression] {
        let deleted = impressionsStatus.filter { $0.value == StorageRecordStatus.deleted }.keys
        let poped = Array(storedImpressions.values.filter { !deleted.contains($0.storageId ?? "") }.prefix(count))
        for impression in poped {
            impressionsStatus[impression.storageId ?? ""] = StorageRecordStatus.deleted
        }
        return poped
    }

    func push(impression: Impression) {
        if let eId = impression.storageId {
            storedImpressions[eId] = impression
            impressionsStatus[eId] = StorageRecordStatus.active
        }
    }

    func getCritical() -> [Impression] {
        return []
    }

    func setActive(_ impressions: [Impression]) {
        for impression in impressions {
            if let eId = impression.storageId {
                impressionsStatus[eId] = StorageRecordStatus.active
            }
        }
    }
}
