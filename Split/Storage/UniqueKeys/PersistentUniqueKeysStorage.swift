//
//  PersistentUniqueKeysStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol PersistentUniqueKeysStorage {
    func delete(_ keys: [UniqueKey])
    func pop(count: Int) -> [UniqueKey]
    func pushMany(keys: [UniqueKey])
    func setActiveAndUpdateSendCount(_ ids: [String])
}

class DefaultPersistentUniqueKeysStorage: PersistentUniqueKeysStorage {

    private let uniqueKeyDao: UniqueKeyDao
    private let expirationPeriod: Int64

    init(database: SplitDatabase, expirationPeriod: Int64) {
        self.uniqueKeyDao = database.uniqueKeyDao
        self.expirationPeriod = expirationPeriod
    }

    func pop(count: Int) -> [UniqueKey] {
        let createdAt = Date().unixTimestamp() - self.expirationPeriod
        let keys = uniqueKeyDao.getBy(createdAt: createdAt,
                                      status: StorageRecordStatus.active,
                                      maxRows: count)
        uniqueKeyDao.update(ids: keys.compactMap { $0.storageId ?? "nil"}.filter { $0 != "nil" },
                            newStatus: StorageRecordStatus.deleted,
                            incrementSentCount: false)
        return keys
    }

    func pushMany(keys: [UniqueKey]) {
        uniqueKeyDao.insert(keys)
    }

    func getCritical() -> [UniqueKey] {
        // To be used in the future.
        return []
    }

    func setActiveAndUpdateSendCount(_ ids: [String]) {
        if ids.count < 1 {
            return
        }
        uniqueKeyDao.update(ids: ids, newStatus: StorageRecordStatus.active, incrementSentCount: true)
    }

    func delete(_ keys: [UniqueKey]) {
        uniqueKeyDao.delete(keys.map { $0.userKey })
    }
}
