//
//  AttributesStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Gonna be replaced by AttributesStorage and ByKeyAttributesStorage")
protocol OneKeyAttributesStorage {
    func loadLocal()
    func set(_ attributes: [String: Any])
    func set(value: Any, name: String)
    func getAll() -> [String: Any]
    func get(name: String) -> Any?
    func remove(name: String)
    func clear()
    func destroy()
}

@available(*, deprecated, message: "Gonna be replaced by AttributesStorage and ByKeyAttributesStorage")
class OneKeyDefaultAttributesStorage: OneKeyAttributesStorage {

    private let inMemoryAttributes: ConcurrentDictionary<String, Any>
    private let persistentStorage: OneKeyPersistentAttributesStorage?

    init(persistentAttributesStorage: OneKeyPersistentAttributesStorage? = nil) {
        persistentStorage = persistentAttributesStorage
        inMemoryAttributes = ConcurrentDictionary<String, Any>()
    }

    func loadLocal() {
        if let attributes = persistentStorage?.getAll() {
            inMemoryAttributes.setValues(attributes)
        }
    }

    func set(_ attributes: [String: Any]) {
        inMemoryAttributes.putValues(attributes)
        persistentStorage?.set(inMemoryAttributes.all)
    }

    func getAll() -> [String: Any] {
        return inMemoryAttributes.all
    }

    func get(name: String) -> Any? {
        return inMemoryAttributes.value(forKey: name)
    }

    func remove(name: String) {
        inMemoryAttributes.removeValue(forKey: name)
        persistentStorage?.set(inMemoryAttributes.all)
    }

    func set(value: Any, name: String) {
        inMemoryAttributes.setValue(value, forKey: name)
        persistentStorage?.set(inMemoryAttributes.all)
    }

    func clear() {
        inMemoryAttributes.removeAll()
        persistentStorage?.clear()
    }

    func destroy() {
        inMemoryAttributes.removeAll()
    }
}
