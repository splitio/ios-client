//
//  AttributesStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 04-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol AttributesStorage {
    func loadLocal(forKey key: String)
    func set(_ attributes: [String: Any], forKey key: String)
    func set(value: Any, name: String, forKey key: String)
    func getAll(forKey key: String) -> [String: Any]
    func get(name: String, forKey key: String) -> Any?
    func remove(name: String, forKey key: String)
    func clear(forKey key: String)
    func destroy(forKey key: String)
}

class DefaultAttributesStorage: AttributesStorage {

    private let inMemoryAttributes: SynchronizedDictionaryComposed<String, String>
    private let persistentStorage: PersistentAttributesStorage?

    init(persistentAttributesStorage: PersistentAttributesStorage? = nil) {
        persistentStorage = persistentAttributesStorage
        inMemoryAttributes = SynchronizedDictionaryComposed()
    }

    func loadLocal(forKey key: String) {
        if let attributes = persistentStorage?.getAll(forKey: key) {
            inMemoryAttributes.set(attributes, forKey: key)
        }
    }

    func set(_ attributes: [String: Any], forKey key: String) {
        inMemoryAttributes.putValues(attributes, forKey: key)
        persistentStorage?.set(inMemoryAttributes.values(forKey: key) ?? [:], forKey: key)
    }

    func getAll(forKey key: String) -> [String: Any] {
        return inMemoryAttributes.values(forKey: key) ?? [:]
    }

    func get(name: String, forKey key: String) -> Any? {
        return inMemoryAttributes.value(name, forKey: key)
    }

    func remove(name: String, forKey key: String) {
        inMemoryAttributes.removeValue(name, forKey: key)
        persistentStorage?.set(inMemoryAttributes.values(forKey: key) ?? [:], forKey: key)
    }

    func set(value: Any, name: String, forKey key: String) {
        inMemoryAttributes.set(value, forInnerKey: name, forKey: key)
        persistentStorage?.set(inMemoryAttributes.values(forKey: key) ?? [:], forKey: key)
    }

    func clear(forKey key: String) {
        inMemoryAttributes.removeValues(forKey: key)
        persistentStorage?.clear(forKey: key)
    }

    func destroy(forKey key: String) {
        inMemoryAttributes.removeValues(forKey: key)
    }
}
