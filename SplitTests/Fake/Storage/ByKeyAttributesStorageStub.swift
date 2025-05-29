//
//  ByKeyAttributesStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

//
//  ByKeyAttributesStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 07-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class ByKeyAttributesStorageStub: ByKeyAttributesStorage {
    let attributesStorage: AttributesStorageStub
    private let userKey: String

    init(userKey: String, attributesStorage: AttributesStorageStub) {
        self.userKey = userKey
        self.attributesStorage = attributesStorage
    }

    var loadLocalCalled = false
    func loadLocal() {
        loadLocalCalled = true
        attributesStorage.loadLocal(forKey: userKey)
    }

    func set(_ attributes: [String: Any]) {
        attributesStorage.set(attributes, forKey: userKey)
    }

    func set(value: Any, name: String) {
        attributesStorage.set(value: value, name: name, forKey: userKey)
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

    func clear() {
        attributesStorage.clear(forKey: userKey)
    }

    var destroyCalled = false
    func destroy() {
        destroyCalled = true
        attributesStorage.destroy(forKey: userKey)
    }
}
