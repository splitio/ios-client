//
//  ConcurrentDictionaryList.swift
//  Split
//
//  Created by Javier on 17/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class ConcurrentDictionaryList<K: Hashable, T> {

    private var queue = DispatchQueue(label: "Split.ConcurrentDictionaryList",
                                      attributes: .concurrent)
    private var items = [K: [T]]()

    var all: [K: [T]] {
        var allItems: [K: [T]]?
        queue.sync {
            allItems = items
        }
        return allItems ?? [K: [T]]()
    }

    var count: Int {
        var count: Int = 0
        queue.sync {
            for (_, values) in items {
                count += values.count
            }
        }
        return count
    }

    func value(forKey key: K) -> [T]? {
        var value: [T]?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func removeValues(forKeys keys: [K]) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                for key in keys {
                    self.items.removeValue(forKey: key)
                }
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.items.removeAll()
            }
        }
    }

    func appendValue(_ value: T, toKey key: K) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                var values = self.items[key] ?? []
                values.append(value)
                self.items[key] = values
            }
        }
    }

    func takeAll() -> [K: [T]] {
        var allItems: [K: [T]]?
        queue.sync {
            allItems = self.items
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self.items.removeAll()
            }
        }
        return allItems ?? [K: [T]]()
    }
}
