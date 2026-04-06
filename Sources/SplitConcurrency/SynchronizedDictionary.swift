//
//  SynchronizedDictionary.swift
//  Split
//
//  Created by Javier on 12-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

public class SynchronizedDictionary<K: Hashable, T>: @unchecked Sendable {

    private var queue: DispatchQueue = DispatchQueue(label: "split-synchronized-dictionary", target: .global())
    private var items = [K: T]()

    public init() {}

    public var keys: Set<K> {
        queue.sync {
            let keys = items.keys
            return Set(keys.map { $0 as K})
        }
    }
    public var all: [K: T] {
        var allItems: [K: T]?
        queue.sync {
            allItems = items
        }
        return allItems!
    }

    public var count: Int {
        var count: Int = 0
        queue.sync {
            count  = items.count
        }
        return count
    }

    public func value(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
        }
        return value
    }

    public func removeValue(forKey key: K) {
        queue.sync {
            _ = items.removeValue(forKey: key)
        }
    }

    public func removeValues(forKeys keys: Dictionary<K, T>.Keys) {
        queue.sync {
            for key in keys {
                items.removeValue(forKey: key)
            }
        }
    }

    public func removeAll() {
        queue.sync {
            items.removeAll()
        }
    }

    public func setValue(_ value: T, forKey key: K) {
        queue.sync {
            items[key] = value
        }
    }

    public func setValues(_ values: [K: T]) {
        queue.sync {
            items.removeAll()
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    public func putValues(_ values: [K: T]) {
        queue.sync {
            for (key, value) in values {
                items[key] = value
            }
        }
    }

    public func takeValue(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = items[key]
            if value != nil {
                items.removeValue(forKey: key)
            }
        }
        return value
    }

    public func takeAll() -> [K: T] {
        var allItems: [K: T]!
        queue.sync {
            allItems = items
            items.removeAll()
        }
        return allItems
    }
}
