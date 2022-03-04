//
//  PersistentAttributesStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2021.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Gonna be replaced by PersistentAttributesStorage")
protocol OneKeyPersistentAttributesStorage {
    func set(_ attributes: [String: Any])
    func getAll() -> [String: Any]?
    func clear()
}

@available(*, deprecated, message: "Gonna be replaced by PersistentAttributesStorage")
class DefaultOneKeyPersistentAttributesStorage: OneKeyPersistentAttributesStorage {

    private let attributesDao: AttributesDao
    private let userKey: String

    init(userKey: String, database: SplitDatabase) {
        self.userKey = userKey
        self.attributesDao = database.attributesDao
    }

    func set(_ attributes: [String: Any]) {
        attributesDao.update(userKey: userKey, attributes: attributes)
    }

    func getAll() -> [String: Any]? {
        return attributesDao.getBy(userKey: userKey)
    }

    func clear() {
        attributesDao.update(userKey: userKey, attributes: nil)
    }
}
