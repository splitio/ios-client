//
//  HashedImpressionDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/11/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import CoreData

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

            result = self.coreDataHelper.fetch(entity: .hashedImpression,
                                               where: nil,
                                               rowLimit: ServiceConstants.lastSeenImpressionCachSize * 2)
            .compactMap { return $0 as? HashedImpressionEntity }
            .compactMap { return self.mapEntityToModel($0) }

            print("what")
            print(result)
        }
        print("what 1")
        return result
    }

    func update(_ hashes: [HashedImpression]) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: .hashedImpression)
            for hash in hashes {
                self.insertOrUpdate(hash)
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ hashes: [HashedImpression]) {
        if hashes.count == 0 {
            return
        }
        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .hashedImpression,
                                       by: "impressionHash", values: hashes.map { Int($0.impressionHash) })
            self.coreDataHelper.save()
        }
    }

    private func insertOrUpdate(_ hashed: HashedImpression) {
        if let obj = self.getBy(hash: hashed.impressionHash) ??
            self.coreDataHelper.create(entity: .hashedImpression) as? HashedImpressionEntity {
            obj.impressionHash = hashed.impressionHash
            obj.time = hashed.time
            obj.createdAt = Date().unixTimestamp()
            self.coreDataHelper.save()
        }
    }

    private func getBy(hash: UInt32) -> HashedImpressionEntity? {
        let predicate = NSPredicate(format: "impressionHash == %d", hash)
        let entities = coreDataHelper.fetch(entity: .hashedImpression,
                                            where: predicate).compactMap { return $0 as? HashedImpressionEntity }
        return entities.count > 0 ? entities[0] : nil
    }

    private func mapEntityToModel(_ entity: HashedImpressionEntity) -> HashedImpression {
        return HashedImpression(impressionHash: entity.impressionHash,
                                time: entity.time,
                                createdAt: entity.createdAt)
    }
}
