//
//  PersistentUniqueKeysStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol PersistentUniqueKeysStorage {
    func set(_ features: [String], forKey key: String)
    func getSnapshot(forKey key: String) -> [String]
}

class DefaultPersistentUniqueKeysStorage: PersistentUniqueKeysStorage {

    private let uniqueKeysDao: UniqueKeyDao

    init(database: SplitDatabase) {
        self.uniqueKeysDao = database.uniqueKeyDao
    }

    func set(_ features: [String], forKey key: String) {
        uniqueKeysDao.update(userKey: key, featureList: features)
    }

    func getSnapshot(forKey key: String) -> [String] {
        return uniqueKeysDao.getBy(userKey: key)
    }
}
