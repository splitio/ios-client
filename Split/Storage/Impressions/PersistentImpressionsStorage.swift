//
//  PersistentImpressionsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentImpressionsStorage {
    func delete(_ impressions: [Impression])
    func pop(count: Int) -> [Impression]
    func push(impression: Impression)
    func getCritical() -> [Impression]
    func setActive(_ impressions: [Impression])
}

class DefaultImpressionsStorage: PersistentImpressionsStorage {

    private let impressionDao: ImpressionDao
    private let expirationPeriod: Int64

    init(database: SplitDatabase, expirationPeriod: Int64) {
        self.impressionDao = database.impressionDao
        self.expirationPeriod = expirationPeriod
    }

    func pop(count: Int) -> [Impression] {
        let createdAt = Date().unixTimestamp() - self.expirationPeriod
        let impressions = impressionDao.getBy(createdAt: createdAt, status: StorageRecordStatus.active, maxRows: count)
        impressionDao.update(ids: impressions.compactMap { $0.storageId }, newStatus: StorageRecordStatus.deleted)
        return impressions
    }

    func push(impression: Impression) {
        impressionDao.insert(impression)
    }

    func getCritical() -> [Impression] {
        // To be used in the future.
        return []
    }

    func setActive(_ impressions: [Impression]) {
        if impressions.count < 1 {
            return
        }
        impressionDao.update(ids: impressions.compactMap { return $0.storageId }, newStatus: StorageRecordStatus.active)
    }

    func delete(_ impressions: [Impression]) {
        impressionDao.delete(impressions)
    }
}
