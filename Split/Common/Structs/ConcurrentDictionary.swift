//
//  SyncDictionarySingleWrapper.swift
//  Split
//
//  Created by Javier on 17/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class ConcurrentDictionary<K: Hashable, T> {

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
        queue = DispatchQueue(label: "Split.ConcurrentDictionary",
                              attributes: .concurrent)
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
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.items.removeValue(forKey: key)
            }
        }
    }

    func removeValues(forKeys keys: Dictionary<K, T>.Keys) {
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

    func setValue(_ value: T, forKey key: K) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.items[key] = value
        }
    }

    func setValues(_ values: [K: T]) {
        queue.async(flags: .barrier) {  [weak self] in
            guard let self = self else { return }
            self.items.removeAll()
            for (key, value) in values {
                self.items[key] = value
            }
        }
    }

    func putValues(_ values: [K: T]) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                for (key, value) in values {
                    self.items[key] = value
                }
            }
        }
    }

    func takeValue(forKey key: K) -> T? {
        var value: T?
        queue.sync {
            value = self.items[key]
            if value != nil {
                queue.async(flags: .barrier) {  [weak self] in
                    guard let self = self else { return }
                    self.items.removeValue(forKey: key)
                }
            }
        }
        return value
    }

    func takeAll() -> [K: T] {
        var allItems: [K: T]!
        queue.sync {
            allItems = items
            queue.async(flags: .barrier) {  [weak self] in
                guard let self = self else { return }
                self.items.removeAll()
            }
        }
        return allItems
    }
}
