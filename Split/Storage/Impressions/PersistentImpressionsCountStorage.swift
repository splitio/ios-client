//
//  PersistentImpressionsCountStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol PersistentImpressionsCountStorage {
    func delete(_ counts: [ImpressionsCountPerFeature])
    func pop(count: Int) -> [ImpressionsCountPerFeature]
    func pushMany(counts: [ImpressionsCountPerFeature])
    func setActive(_ counts: [ImpressionsCountPerFeature])
}

class DefaultImpressionsCountStorage: PersistentImpressionsCountStorage {

    private let impressionsCountDao: ImpressionsCountDao
    private let expirationPeriod: Int64

    init(database: SplitDatabase, expirationPeriod: Int64) {
        self.impressionsCountDao = database.impressionsCountDao
        self.expirationPeriod = expirationPeriod
    }

    func pop(count: Int) -> [ImpressionsCountPerFeature] {
        let createdAt = Date().unixTimestamp() - self.expirationPeriod
        let counts = impressionsCountDao.getBy(createdAt: createdAt,
                                                    status: StorageRecordStatus.active,
                                                    maxRows: count)
        impressionsCountDao.update(ids: counts.compactMap { $0.storageId },
                                   newStatus: StorageRecordStatus.deleted)
        return counts
    }

    func pushMany(counts: [ImpressionsCountPerFeature]) {
        impressionsCountDao.insert(counts)
    }

    func getCritical() -> [ImpressionsCountPerFeature] {
        // To be used in the future.
        return []
    }

    func setActive(_ counts: [ImpressionsCountPerFeature]) {
        if counts.count < 1 {
            return
        }
        impressionsCountDao.update(ids: counts.compactMap { return $0.storageId },
                                   newStatus: StorageRecordStatus.active)
    }

    func delete(_ counts: [ImpressionsCountPerFeature]) {
        impressionsCountDao.delete(counts)
    }
}
