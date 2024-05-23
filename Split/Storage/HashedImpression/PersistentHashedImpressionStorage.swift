//
//  PersistentHashedImpressionStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentHashedImpressionStorage {
    func set(_ hashes: [HashedImpression])
    func getAll() -> [HashedImpression]
}

class DefaultPersistentHashedImpressionsStorage: PersistentHashedImpressionStorage {

    private let hashedImpressionDao: HashedImpressionDao

    init(database: SplitDatabase) {
        self.hashedImpressionDao = database.hashedImpressionDao
    }

    func set(_ hashes: [HashedImpression]) {
        hashedImpressionDao.set(hashes)
    }

    func getAll() -> [HashedImpression] {
        return hashedImpressionDao.getAll()
    }
}
