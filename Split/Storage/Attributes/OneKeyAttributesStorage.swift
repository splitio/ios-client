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
    func set(_ attributes: [String: AnySendable])
    func set(value: AnySendable, name: String)
    func getAll() -> [String: AnySendable]
    func get(name: String) -> AnySendable?
    func remove(name: String)
    func clear()
    func destroy()
}

@available(*, deprecated, message: "Gonna be replaced by AttributesStorage and ByKeyAttributesStorage")
class OneKeyDefaultAttributesStorage: OneKeyAttributesStorage, @unchecked Sendable {

    private let inMemoryAttributes: ConcurrentDictionary<String, AnySendable>
    private let persistentStorage: OneKeyPersistentAttributesStorage?

    init(persistentAttributesStorage: OneKeyPersistentAttributesStorage? = nil) {
        persistentStorage = persistentAttributesStorage
        inMemoryAttributes = ConcurrentDictionary<String, AnySendable>()
    }

    func loadLocal() {
        if let attributes = persistentStorage?.getAll() {
            let sendableAttributes = attributes.mapValues { AnySendable(value: $0) }
            inMemoryAttributes.setValues(sendableAttributes)
        }
    }

    func set(_ attributes: [String: AnySendable]) {
        inMemoryAttributes.putValues(attributes)
        persistentStorage?.set(inMemoryAttributes.all)
    }

    func getAll() -> [String: AnySendable] {
        return inMemoryAttributes.all
    }

    func get(name: String) -> AnySendable? {
        return inMemoryAttributes.value(forKey: name)
    }

    func remove(name: String) {
        inMemoryAttributes.removeValue(forKey: name)
        persistentStorage?.set(inMemoryAttributes.all)
    }

    func set(value: AnySendable, name: String) {
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

struct AnySendable: @unchecked Sendable {
    let value: Any
}
