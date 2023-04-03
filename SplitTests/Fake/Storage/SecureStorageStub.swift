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
            Logger.e("Error parsing item \(key.rawValue)")
        }
    }

    func get(item: SecureItem) -> String? {
        return values[item.rawValue]
    }

    func get<T: Decodable>(item: SecureItem, type: T.Type) -> T? {
        guard let data = get(item: item) else {
            return nil
        }
        do {
            return try Json.encodeFrom(json: data, to: type)
        } catch {
            Logger.d("Couldn't get \(item.rawValue) item")
        }
        return nil
    }

    func remove(item: SecureItem) {
        values.removeValue(forKey: item.rawValue)
    }

    func set(item: String, for key: SecureItem) {
        values[key.rawValue] = item
    }



}
