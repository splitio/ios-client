//
//  ConcurrentSet.swift
//  Split
//
//  Created by Javier on 09-Nov-2020.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class ConcurrentSet<T: Hashable> {
    private var queue: DispatchQueue
    private var items: Set<T>

    var all: Set<T> {
        var allItems: Set<T>?
        queue.sync {
            allItems = items
        }
        return allItems ?? Set<T>()
    }

    var count: Int {
        var count: Int = 0
        queue.sync {
            count = items.count
        }
        return count
    }

    init() {
        queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        items = Set<T>()
    }

    func insert(_ item: T) {
        queue.async(flags: .barrier) {
            self.items.insert(item)
        }
    }

    func set(_ items: [T]) {
        queue.async(flags: .barrier) {
            self.items.removeAll()
            for item in items {
                self.items.insert(item)
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }

    func takeAll() -> Set<T> {
        var allItems: Set<T>?
        queue.sync {
            allItems = self.items
            queue.async(flags: .barrier) {
                self.items.removeAll()
            }
        }
        return allItems ?? Set<T>()
    }
}
