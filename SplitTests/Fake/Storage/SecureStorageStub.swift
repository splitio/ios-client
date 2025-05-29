//
//  SecureStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03-Apr-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class SecureStorageStub: KeyValueStorage {
    var values = [String: String]()
    func set<T: Encodable>(item: T, for key: SecureItem) {
        do {
            let json = try Json.encodeToJson(item)
            set(item: json, for: key)
        } catch {
            Logger.e("Error parsing item \(key.toString())")
        }
    }

    func getString(item: SecureItem) -> String? {
        return values[item.toString()]
    }

    func get<T: Decodable>(item: SecureItem, type: T.Type) -> T? {
        guard let data = getString(item: item) else {
            return nil
        }
        do {
            return try Json.decodeFrom(json: data, to: type)
        } catch {
            Logger.d("Couldn't get \(item.toString()) item")
        }
        return nil
    }

    func remove(item: SecureItem) {
        values.removeValue(forKey: item.toString())
    }

    func set(item: String, for key: SecureItem) {
        values[key.toString()] = item
    }

    func getInt(item: SecureItem) -> Int? {
        let value = values[item.toString()] ?? ""
        return Int(value)
    }

    func set(item: Int, for key: SecureItem) {
        values[key.toString()] = "\(item)"
    }
}
