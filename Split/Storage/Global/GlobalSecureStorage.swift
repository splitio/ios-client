//
//  GlobalSecureStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/29/2021.
//  Copyright © 2021 Split. All rights reserved.
//
import Foundation

class GlobalSecureStorage: KeyValueStorage {

    static let shared: KeyValueStorage = GlobalSecureStorage()

    func set<T: Encodable>(item: T, for key: SecureItem) {
        do {
            let json = try Json.encodeToJson(item)
            set(item: json, for: key)
        } catch {
            Logger.e("Error parsing item \(key.rawValue)")
        }
    }

    func get(item: SecureItem) -> String? {

        let itemName = item.rawValue
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemName
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
        let itemName = item.rawValue
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: itemName
        ]

        let resultCode = SecItemDelete(queryDelete as CFDictionary)
        Logger.d((resultCode == noErr ?
                    "Removed '\(item)'" :
                    "Error deleting from Keychain: \(resultCode)"))
    }

    func set(item: String, for key: SecureItem) {

        if get(item: key) != nil {
            remove(item: key)
        }

        guard let itemData = item.data(using: String.Encoding.utf8) else {
            Logger.e("Error saving text to Keychain")
            return
        }

        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: itemData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
        Logger.d((resultCode == noErr ?
                    "Updated \(key)" :
                    "Could not update '\(key)': \(resultCode)"))
    }

}
