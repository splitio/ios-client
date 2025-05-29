//
//  PersistentHashedImpressionStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentHashedImpressionsStorage {
    func update(_ hashes: [HashedImpression])
    func delete(_ hashes: [HashedImpression])
    func getAll() -> [HashedImpression]
}

class DefaultPersistentHashedImpressionsStorage: PersistentHashedImpressionsStorage {
    private let hashedImpressionDao: HashedImpressionDao

    init(database: SplitDatabase) {
        self.hashedImpressionDao = database.hashedImpressionDao
    }

    func update(_ hashes: [HashedImpression]) {
        hashedImpressionDao.update(hashes)
    }

    func delete(_ hashes: [HashedImpression]) {
        hashedImpressionDao.delete(hashes)
    }

    func getAll() -> [HashedImpression] {
        return hashedImpressionDao.getAll()
    }
}
