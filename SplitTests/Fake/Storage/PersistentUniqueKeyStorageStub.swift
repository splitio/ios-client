//
//  PersistentUniqueKeyStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 20-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentUniqueKeyStorageStub: PersistentUniqueKeysStorage {
    struct Record {
        var uniqueKey: UniqueKey
        var sendAttempCount: Int16
        var recordStatus: Int32
    }

    var uniqueKeys = [String: Record]()

    func delete(_ keys: [UniqueKey]) {
        for key in keys {
            if let storageId = key.storageId {
                uniqueKeys.removeValue(forKey: storageId)
            }
        }
    }

    func pop(count: Int) -> [UniqueKey] {
        let resp = uniqueKeys.values.filter {
            $0.recordStatus == StorageRecordStatus.active

        }.prefix(count)
        for value in resp {
            uniqueKeys[value.uniqueKey.userKey]?.recordStatus = StorageRecordStatus.deleted
        }
        return resp.map { $0.uniqueKey }
    }

    func pushMany(keys: [UniqueKey]) {
        for key in keys {
            let storageId = UUID().uuidString
            let newKey = UniqueKey(
                storageId: storageId,
                userKey: key.userKey,
                features: key.features)
            uniqueKeys[storageId] = Record(
                uniqueKey: newKey,
                sendAttempCount: 0,
                recordStatus: StorageRecordStatus.active)
        }
    }

    func setActiveAndUpdateSendCount(_ ids: [String]) {
        for elementId in ids {
            if var key = uniqueKeys[elementId] {
                key.recordStatus = StorageRecordStatus.active
                key.sendAttempCount += 1
                uniqueKeys[elementId] = key
            }
        }
    }

    func clear() {
        uniqueKeys.removeAll()
    }
}
