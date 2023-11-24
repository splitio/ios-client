//
//  KeyValueStorageMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24/11/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class KeyValueStorageMock: KeyValueStorage {
    private var storage: [String: Any] = [:]

    func set<T: Encodable>(item: T, for key: SecureItem) {
        storage[key.toString()] = item
    }

    func getInt(item: SecureItem) -> Int? {
        return storage[item.toString()] as? Int
    }

    func get<T: Decodable>(item: SecureItem, type: T.Type) -> T? {
        return storage[item.toString()] as? T
    }

    func getString(item: SecureItem) -> String? {
        return storage[item.toString()] as? String
    }

    func remove(item: SecureItem) {
        storage.removeValue(forKey: item.toString())
    }

    func set(item: String, for key: SecureItem) {
        storage[key.toString()] = item
    }

    func set(item: Int, for key: SecureItem) {
        storage[key.toString()] = item
    }
}
