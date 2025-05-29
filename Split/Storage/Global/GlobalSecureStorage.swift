//
//  GlobalSecureStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/29/2021.
//  Copyright © 2021 Split. All rights reserved.
//
import Foundation

class GlobalSecureStorage: KeyValueStorage {
    private static let prodStorage: KeyValueStorage = GlobalSecureStorage()

    // Only for testing
    static var testStorage: KeyValueStorage?

    static var shared: KeyValueStorage {
        return testStorage ?? prodStorage
    }

    func set<T: Encodable>(item: T, for key: SecureItem) {
        do {
            let json = try Json.encodeToJson(item)
            set(item: json, for: key)
        } catch {
            Logger.e("Error parsing item \(key.toString())")
        }
    }

    func getString(item: SecureItem) -> String? {
        let itemName = item.toString()
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemName,
        ]
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue

        var item: CFTypeRef?
        var status: OSStatus = noErr

        status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == noErr,
           let dic = item as? [String: Any],
           let data = dic[kSecValueData as String] as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
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

    func getInt(item: SecureItem) -> Int? {
        guard let data = getString(item: item) else {
            return nil
        }
        return Int(data)
    }

    func remove(item: SecureItem) {
        let itemName = item.toString()
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemName,
        ]

        let resultCode = SecItemDelete(queryDelete as CFDictionary)
        Logger.d(
            resultCode == noErr ?
                "Removed '\(item)'" :
                "Error deleting from Keychain: \(resultCode)")
    }

    func set(item: Int, for key: SecureItem) {
        set(item: "\(item)", for: key)
    }

    func set(item: String, for key: SecureItem) {
        if getString(item: key) != nil {
            remove(item: key)
        }

        guard let itemData = item.data(using: String.Encoding.utf8) else {
            Logger.e("Error saving text to Keychain")
            return
        }

        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.toString(),
            kSecValueData as String: itemData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
        Logger.d(
            resultCode == noErr ?
                "Updated \(key)" :
                "Could not update '\(key)': \(resultCode)")
    }
}
