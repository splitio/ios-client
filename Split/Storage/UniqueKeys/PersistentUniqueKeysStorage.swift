//
//  PersistentUniqueKeysStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol PersistentUniqueKeysStorage {
    func delete(_ counts: [UniqueKey])
    func pop(count: Int) -> [UniqueKey]
    func pushMany(keys: [UniqueKey])
    func setActive(_ counts: [UniqueKey])
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
        uniqueKeyDao.update(keys: keys.map { $0.userKey },
                            newStatus: StorageRecordStatus.deleted)
        return keys
    }

    func pushMany(keys: [UniqueKey]) {
        uniqueKeyDao.insert(keys)
    }

    func getCritical() -> [UniqueKey] {
        // To be used in the future.
        return []
    }

    func setActive(_ keys: [UniqueKey]) {
        if keys.count < 1 {
            return
        }
        uniqueKeyDao.update(keys: keys.compactMap { return $0.userKey },
                            newStatus: StorageRecordStatus.active)
    }

    func delete(_ keys: [UniqueKey]) {
        uniqueKeyDao.delete(keys.map { $0.userKey })
    }
}
