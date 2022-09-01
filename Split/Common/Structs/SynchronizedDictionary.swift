//
//  SynchronizedDictionary.swift
//  Split
//
//  Created by Javier on 12-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SynchronizedDictionary<K: Hashable, T> {

    private var queue: DispatchQueue = DispatchQueue(label: "Split.SynchronizedDictionary", target: .global())
    private var items = [K: T]()

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
            count  = items.count
        }
        return count
    }

    func value(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func removeValue(forKey key: K) {
        queue.sync {
            _ = items.removeValue(forKey: key)
        }
    }

    func removeValues(forKeys keys: Dictionary<K, T>.Keys) {
        queue.sync {
            for key in keys {
                items.removeValue(forKey: key)
            }
        }
    }

    func removeAll() {
        queue.sync {
            items.removeAll()
        }
    }

    func setValue(_ value: T, forKey key: K) {
        queue.sync {
            items[key] = value
        }
    }

    func setValues(_ values: [K: T]) {
        queue.sync {
            items.removeAll()
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    func putValues(_ values: [K: T]) {
        queue.sync {
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    func takeValue(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
            if value != nil {
                items.removeValue(forKey: key)
            }
        }
        return value
    }

    func takeAll() -> [K: T] {
        var allItems: [K: T]!
        queue.sync {
            allItems = items
            items.removeAll()
        }
        return allItems
    }
}
