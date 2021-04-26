//
//  KeyValueStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/29/2021.
//  Copyright © 2021 Split. All rights reserved.
//
import Foundation

enum SecureItem: String {
    case backgroundSyncSchedule = "bgSyncSchedule"
}

protocol KeyValueStorage {
    func set<T: Encodable>(item: T, for key: SecureItem)
    func get<T: Decodable>(item: SecureItem, type: T.Type) -> T?
    func remove(item: SecureItem)
    func set(item: String, for key: SecureItem)
}
