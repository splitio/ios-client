//
//  PersistentAttributesStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 04-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol PersistentAttributesStorage {
    func set(_ attributes: [String: Any], forKey key: String)
    func getAll(forKey key: String) -> [String: Any]?
    func clear(forKey key: String)
}

class DefaultPersistentAttributesStorage: PersistentAttributesStorage {

    private let attributesDao: AttributesDao

    init(database: SplitDatabase) {
        self.attributesDao = database.attributesDao
    }

    func set(_ attributes: [String: Any], forKey key: String) {
        attributesDao.update(userKey: key, attributes: attributes)
    }

    func getAll(forKey key: String) -> [String: Any]? {
        return attributesDao.getBy(userKey: key)
    }

    func clear(forKey key: String) {
        attributesDao.update(userKey: key, attributes: nil)
    }
}
