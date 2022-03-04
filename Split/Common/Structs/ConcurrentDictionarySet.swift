//
//  ConcurrentDictionarySet.swift
//  Split
//
//  Created by Javier on 3-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class ConcurrentDictionarySet<K: Hashable, T: Hashable> {

    private var queue: DispatchQueue = DispatchQueue(label: "split-concurrent-dictionary-map",
                                                     attributes: .concurrent)
    private var items = [K: Set<T>]()

    func count(forKey key: K) -> Int {
        var count: Int?
        queue.sync {
            count = items[key]?.count
        }
        return count ?? 0
    }

    func values(forKey key: K) -> Set<T>? {
        var value: Set<T>?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func contains(value: T, forKey key: K) -> Bool {
        var hasValue: Bool?
        queue.sync {
            hasValue = items[key]?.contains(value)
        }
        return hasValue ?? false
    }

    func set(_ values: Set<T>, forKey key: K) {
        queue.async(flags: .barrier) {
            self.items[key] = values
        }
    }

    func removeValues(forKey key: K) {
        queue.async(flags: .barrier) {
            self.items.removeValue(forKey: key)
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }
}
