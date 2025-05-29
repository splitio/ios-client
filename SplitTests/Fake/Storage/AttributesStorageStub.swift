//
//  AttributesStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class AttributesStorageStub: AttributesStorage {
    var persistedAttributes = [String: [String: Any]]()
    private var attributes = [String: [String: Any]]()

    func loadLocal(forKey key: String) {
        attributes[key] = persistedAttributes[key]
    }

    func set(_ attributes: [String: Any], forKey key: String) {
        var newAttributes = self.attributes[key] ?? [:]
        for (ikey, att) in attributes {
            newAttributes[ikey] = att
        }
        self.attributes[key] = newAttributes
    }

    func set(value: Any, name: String, forKey key: String) {
        var newAttributes = attributes[key] ?? [:]
        newAttributes[name] = value
        attributes[key] = newAttributes
    }

    func getAll(forKey key: String) -> [String: Any] {
        return attributes[key] ?? [:]
    }

    func get(name: String, forKey key: String) -> Any? {
        return attributes[key]?[name]
    }

    func remove(name: String, forKey key: String) {
        attributes[key]?.removeValue(forKey: name)
    }

    func clear(forKey key: String) {
        attributes.removeValue(forKey: key)
    }

    var destroyCalled = false
    func destroy(forKey key: String) {
        destroyCalled = true
        attributes.removeValue(forKey: key)
    }
}
