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
    func set(_ hashes: [HashedImpression])
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
                                               rowLimit: ServiceConstants.impressionHashSize)
            .compactMap { return $0 as? HashedImpressionEntity }
            .compactMap { return self.mapEntityToModel($0) }
        }
        return result
    }

    func set(_ hashes: [HashedImpression]) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: .hashedImpression)
            for hash in hashes {
                self.insert(hash)
            }
            self.coreDataHelper.save()
        }
    }

    private func insert(_ hash: HashedImpression) {
        if let obj = self.coreDataHelper.create(entity: .hashedImpression) as? HashedImpressionEntity {
            obj.impressionHash = hash.impressionHash
            obj.time = hash.time
            obj.createdAt = Date().unixTimestamp()
            self.coreDataHelper.save()
        }
    }

    private func mapEntityToModel(_ entity: HashedImpressionEntity) -> HashedImpression {
        return HashedImpression(impressionHash: entity.impressionHash,
                                time: entity.time,
                                createdAt: entity.createdAt)
    }
}
