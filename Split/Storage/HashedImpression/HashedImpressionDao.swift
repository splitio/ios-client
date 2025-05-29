//
//  HashedImpressionDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/11/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import CoreData
import Foundation

protocol HashedImpressionDao {
    func getAll() -> [HashedImpression]
    func update(_ hashes: [HashedImpression])
    func delete(_ hashes: [HashedImpression])
}

class CoreDataHashedImpressionDao: BaseCoreDataDao, HashedImpressionDao {
    override init(coreDataHelper: CoreDataHelper) {
        super.init(coreDataHelper: coreDataHelper)
    }

    func getAll() -> [HashedImpression] {
        var result = [HashedImpression]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            result = self.coreDataHelper.fetch(
                entity: .hashedImpression,
                where: nil,
                rowLimit: ServiceConstants.lastSeenImpressionCachSize * 2)
                .compactMap { $0 as? HashedImpressionEntity }
                .compactMap { self.mapEntityToModel($0) }
        }
        return result
    }

    func update(_ hashes: [HashedImpression]) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            for hash in hashes {
                self.insertOrUpdate(hash)
            }
            self.deleteExpired()
            self.coreDataHelper.save()
        }
    }

    func delete(_ hashes: [HashedImpression]) {
        if hashes.isEmpty {
            return
        }
        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(
                entity: .hashedImpression,
                by: "impressionHash",
                values: hashes.map { Int64($0.impressionHash) })
            self.coreDataHelper.save()
        }
    }

    private func deleteExpired() {
        let expirationTime = Date.nowMillis() - ServiceConstants.hashedImpressionsExpirationMs
        let predicate = NSPredicate(format: "createdAt <= %d", expirationTime)
        execute { [weak self] in
            guard let self = self else {
                return
            }
            let hashes = self.coreDataHelper.fetch(
                entity: .hashedImpression,
                where: predicate)
                .compactMap { $0 as? HashedImpressionEntity }

            self.coreDataHelper.delete(
                entity: .hashedImpression,
                by: "impressionHash",
                values: hashes.map { Int64($0.impressionHash) })
            self.coreDataHelper.save()
        }
    }

    private func insertOrUpdate(_ hashed: HashedImpression) {
        if let obj = getBy(hash: hashed.impressionHash) ??
            coreDataHelper.create(entity: .hashedImpression) as? HashedImpressionEntity {
            obj.impressionHash = hashed.impressionHash
            obj.time = hashed.time
            obj.createdAt = obj.createdAt == 0 ? Date.nowMillis() : obj.createdAt
            coreDataHelper.save()
        }
    }

    private func getBy(hash: UInt32) -> HashedImpressionEntity? {
        let predicate = NSPredicate(format: "impressionHash == %d", hash)
        let entities = coreDataHelper.fetch(
            entity: .hashedImpression,
            where: predicate).compactMap { $0 as? HashedImpressionEntity }
        return !entities.isEmpty ? entities[0] : nil
    }

    private func mapEntityToModel(_ entity: HashedImpressionEntity) -> HashedImpression {
        return HashedImpression(
            impressionHash: entity.impressionHash,
            time: entity.time,
            createdAt: entity.createdAt)
    }
}
