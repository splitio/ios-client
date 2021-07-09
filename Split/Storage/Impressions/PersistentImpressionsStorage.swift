//
//  PersistentImpressionsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentImpressionsStorage {
    func delete(_ impressions: [KeyImpression])
    func pop(count: Int) -> [KeyImpression]
    func push(impression: KeyImpression)
    func getCritical() -> [KeyImpression]
    func setActive(_ impressions: [KeyImpression])
}

class DefaultImpressionsStorage: PersistentImpressionsStorage {

    private let impressionDao: ImpressionDao
    private let expirationPeriod: Int64

    init(database: SplitDatabase, expirationPeriod: Int64) {
        self.impressionDao = database.impressionDao
        self.expirationPeriod = expirationPeriod
    }

    func pop(count: Int) -> [KeyImpression] {
        let createdAt = Date().unixTimestamp() - self.expirationPeriod
        let impressions = impressionDao.getBy(createdAt: createdAt, status: StorageRecordStatus.active, maxRows: count)
        impressionDao.update(ids: impressions.compactMap { $0.storageId }, newStatus: StorageRecordStatus.deleted)
        return impressions
    }

    func push(impression: KeyImpression) {
        impressionDao.insert(impression)
    }

    func getCritical() -> [KeyImpression] {
        // To be used in the future.
        return []
    }

    func setActive(_ impressions: [KeyImpression]) {
        if impressions.count < 1 {
            return
        }
        impressionDao.update(ids: impressions.compactMap { return $0.storageId }, newStatus: StorageRecordStatus.active)
    }

    func delete(_ impressions: [KeyImpression]) {
        impressionDao.delete(impressions)
    }
}
