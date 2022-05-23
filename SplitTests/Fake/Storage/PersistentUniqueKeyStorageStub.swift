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

    struct State {
        var sendAttempCount: Int16
        var recordStatus: Int32
    }

    var uniqueKeys = [String: UniqueKey]()
    var recordState = [String: State]()

    func delete(_ keys: [UniqueKey]) {
        for key in keys {
            if let storageId = key.storageId {
                uniqueKeys.removeValue(forKey: storageId)
            }
        }
    }

    func pop(count: Int) -> [UniqueKey] {
        let resp = uniqueKeys.prefix(count)
        for (key, _) in resp {
            uniqueKeys.removeValue(forKey: key)
        }
        return resp.map { return $0.value }
    }

    func pushMany(keys: [UniqueKey]) {
        for key in keys {
            let storageId = UUID().uuidString
            let newKey = UniqueKey(storageId: storageId,
                                   userKey: key.userKey,
                                   features: key.features)
            uniqueKeys[storageId] = newKey
        }
    }

    func setActiveAndUpdateSendCount(_ ids: [String]) {
        for elementId in ids {
            var status = recordState[elementId] ?? State(sendAttempCount: 0, recordStatus: StorageRecordStatus.active)
            status.recordStatus = StorageRecordStatus.active
            status.sendAttempCount+=1
            recordState[elementId] = status
        }
    }

    func clear() {
        uniqueKeys.removeAll()
        recordState.removeAll()
    }
}
