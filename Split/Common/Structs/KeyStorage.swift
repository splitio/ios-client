//
//  SplitKeyDictionary.swift
//  Split
//
//  Created by Javier on 29-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SplitKeyDictionary<T> {

    private var queue: DispatchQueue = DispatchQueue(label: "Split.SplitKeyDictionary",
                                                     target: .global())
    private var items = [Key: T]()

    var matchingKeys: Set<String> {
        var allMatchingKeys: Set<String>?
        queue.sync {
            allMatchingKeys = Set(items.keys.map { $0.matchingKey })
        }
        return allMatchingKeys ?? Set<String>()
    }

    var all: [Key: T] {
        var allItems: [Key: T]?
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

    func value(forKey key: Key) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func values(forMatchingKey matchingKey: String) -> [T] {
        var values: [T]?
        queue.sync {
            values = [T]()
            let keys = items.keys.filter { $0.matchingKey == matchingKey }
            for key in keys {
                if let item = items[key] {
                    values?.append(item)
                }
            }
        }
        return values ?? []
    }

    func removeValue(forKey key: Key) {
        queue.sync {
            _ = items.removeValue(forKey: key)
        }
    }

    func removeValues(forKeys keys: Dictionary<Key, T>.Keys) {
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

    func setValue(_ value: T, forKey key: Key) {
        queue.sync {
            items[key] = value
        }
    }

    func setValues(_ values: [Key: T]) {
        queue.sync {
            items.removeAll()
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    func putValues(_ values: [Key: T]) {
        queue.sync {
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    func takeValue(forKey key: Key) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
            if value != nil {
                items.removeValue(forKey: key)
            }
        }
        return value
    }

    func removeAndCount(forKey key: Key) -> Int {
        var count: Int = 0
        queue.sync {
            items.removeValue(forKey: key)
            count = items.count
        }
        return count
    }

    func takeAll() -> [Key: T] {
        var allItems: [Key: T]!
        queue.sync {
            allItems = items
            items.removeAll()
        }
        return allItems
    }
}
