//
//  AttributesStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol AttributesStorage {
    func loadLocal()
    func set(_ attributes: [String: Any])
    func set(value: Any, for key: String)
    func getAll() -> [String: Any]
    func get(for key: String) -> Any?
    func remove(key: String)
    func clear()
    func destroy()
}

class DefaultAttributesStorage: AttributesStorage {

    private let inMemoryAttributes: SyncDictionarySingleWrapper<String, Any>
    private let persistenStorage: PersistentAttributesStorage?

    init(persistentAttributesStorage: PersistentAttributesStorage?) {
        persistenStorage = persistentAttributesStorage
        inMemoryAttributes = SyncDictionarySingleWrapper<String, Any>()
    }

    func loadLocal() {
        if let attributes = persistenStorage?.getAll() {
            inMemoryAttributes.setValues(attributes)
        }
    }

    func set(_ attributes: [String: Any]) {
        inMemoryAttributes.setValues(attributes)
        persistenStorage?.set(attributes)
    }

    func getAll() -> [String: Any] {
        return inMemoryAttributes.all
    }

    func get(for key: String) -> Any? {
        return inMemoryAttributes.value(forKey: key)
    }

    func remove(key: String) {
        inMemoryAttributes.removeValue(forKey: key)
        persistenStorage?.set(inMemoryAttributes.all)
    }

    func set(value: Any, for key: String) {
        inMemoryAttributes.setValue(value, forKey: key)
        persistenStorage?.set(inMemoryAttributes.all)
    }

    func clear() {
        inMemoryAttributes.removeAll()
        persistenStorage?.clear()
    }

    func destroy() {
        inMemoryAttributes.removeAll()
    }
}
