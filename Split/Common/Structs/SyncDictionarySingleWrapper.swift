//
//  SyncDictionarySingleWrapper.swift
//  Split
//
//  Created by Javier on 17/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class SyncDictionarySingleWrapper<K: Hashable, T> {

    private var queue: DispatchQueue
    private var items: [K: T]

    var all: [K: T] {
        var allItems: [K: T]?
        queue.sync {
            allItems = items
        }
        return allItems!
    }

    var count: Int {
        var count: Int = 0
        queue.sync {
            count  = self.items.count
        }
        return count
    }

    init() {
        queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        items = [K: T]()
    }

    func value(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func removeValue(forKey key: K) {
        queue.async(flags: .barrier) {
            self.items.removeValue(forKey: key)
        }
    }

    func removeValues(forKeys keys: Dictionary<K, T>.Keys) {
        queue.async(flags: .barrier) {
            for key in keys {
                self.items.removeValue(forKey: key)
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }

    func setValue(_ value: T, forKey key: K) {
        queue.async(flags: .barrier) {
            self.items[key] = value
        }
    }

    func setValues(_ values: [K: T]) {
        queue.async(flags: .barrier) {
            self.items.removeAll()
            for (key, value) in values {
                self.items[key] = value
            }
        }
    }

    func takeAll() -> [K: T] {
        var allItems: [K: T]!
        queue.sync {
            allItems = items
            queue.async(flags: .barrier) {
                self.items.removeAll()
            }
        }
        return allItems
    }
}
