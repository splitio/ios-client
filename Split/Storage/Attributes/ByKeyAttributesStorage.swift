//
//  ByKeyAttributesStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol ByKeyAttributesStorage {
    func loadLocal()
    func set(_ attributes: [String: Any])
    func set(value: Any, name: String)
    func getAll() -> [String: Any]
    func get(name: String) -> Any?
    func remove(name: String)
    func clear()
    func destroy()
}

class DefaultByKeyAttributesStorage: ByKeyAttributesStorage {

    private let attributesStorage: AttributesStorage
    private let userKey: String

    init(attributesStorage: AttributesStorage,
         userKey: String) {
        self.attributesStorage = attributesStorage
        self.userKey = userKey
    }

    func loadLocal() {
        attributesStorage.loadLocal(forKey: userKey)
    }

    func set(_ attributes: [String: Any]) {
        attributesStorage.set(attributes, forKey: userKey)
    }

    func getAll() -> [String: Any] {
        return attributesStorage.getAll(forKey: userKey)
    }

    func get(name: String) -> Any? {
        return attributesStorage.get(name: name, forKey: userKey)
    }

    func remove(name: String) {
        attributesStorage.remove(name: name, forKey: userKey)
    }

    func set(value: Any, name: String) {
        attributesStorage.set(value: value, name: name, forKey: userKey)
    }

    func clear() {
        attributesStorage.clear(forKey: userKey)
    }

    func destroy() {
        attributesStorage.destroy(forKey: userKey)
    }
}
