//
//  HashedImpressionStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 22/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

protocol HashedImpressionsStorage {
    func loadFromDb()
    func set(_ time: Int64, for hash: UInt32)
    func get(for hash: UInt32) -> Int64?
    func clear()
    func save()
}

class DefaultHashedImpressionsStorage: HashedImpressionsStorage {

    private let cache: LRUCache<UInt32, Int64>
    private let persistentStorage: PersistentHashedImpressionsStorage

    init(cache: LRUCache<UInt32, Int64>,
         persistentStorage: PersistentHashedImpressionsStorage) {

        self.cache = cache
        self.persistentStorage = persistentStorage
    }

    func loadFromDb() {
        let items = persistentStorage.getAll()
        items.forEach { hashed in
            cache.set(hashed.time, for: hashed.impressionHash)
        }
    }

    func set(_ time: Int64, for hash: UInt32) {
        cache.set(time, for: hash)
    }

    func get(for hash: UInt32) -> Int64? {
        return cache.element(for: hash)
    }

    func clear() {
        cache.clear()
    }

    func save() {
        persistentStorage.update(cache.all().map { HashedImpression(impressionHash: $0.key, 
                                                                    time: $0.value,
                                                                    createdAt: $0.value)})
    }
}
