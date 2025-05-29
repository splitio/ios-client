//
//  ConcurrentDictionarySet.swift
//  Split
//
//  Created by Javier on 3-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SynchronizedDictionarySet<K: Hashable, T: Hashable> {
    private var queue: DispatchQueue = .init(
        label: "split-synchronized-dictionary-set",
        target: .global())
    private var items = [K: Set<T>]()

    var keys: Set<K> {
        queue.sync {
            let keys = items.keys
            return Set(keys.map { $0 as K })
        }
    }

    var all: [K: Set<T>] {
        var all: [K: Set<T>]?
        queue.sync {
            all = items
        }
        return all ?? [K: Set<T>]()
    }

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

    func takeAll() -> [K: Set<T>] {
        var all: [K: Set<T>]?
        queue.sync {
            all = items
            items.removeAll()
        }
        return all ?? [K: Set<T>]()
    }

    func contains(value: T, forKey key: K) -> Bool {
        var hasValue: Bool?
        queue.sync {
            hasValue = items[key]?.contains(value)
        }
        return hasValue ?? false
    }

    func set(_ values: Set<T>, forKey key: K) {
        queue.sync {
            self.items[key] = values
        }
    }

    func insert(_ value: T, forKey key: K) {
        queue.sync {
            if items[key] != nil {
                items[key]?.insert(value)
            } else {
                items[key] = Set([value])
            }
        }
    }

    func removeValues(forKey key: K) {
        queue.sync {
            _ = items.removeValue(forKey: key)
        }
    }

    func removeValue(_ value: T, forKey key: K) {
        queue.sync {
            var values = items[key]
            values?.remove(value)

            if (values?.count ?? 0) == 0 {
                items.removeValue(forKey: key)
            } else {
                items[key] = values
            }
        }
    }

    func removeAll() {
        queue.sync {
            items.removeAll()
        }
    }
}
