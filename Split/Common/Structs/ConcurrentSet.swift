//
//  ConcurrentSet.swift
//  Split
//
//  Created by Javier on 09-Nov-2020.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class ConcurrentSet<T: Hashable> {
    private var queue = DispatchQueue(label: "Split.ConcurrentSet",
                                      attributes: .concurrent)
    private var items: Set<T> = Set<T>()
    private var capacity: Int = -1

    init(capacity: Int) {
        if capacity > 0 {
            self.capacity = capacity
        }
    }

    convenience init() {
        self.init(capacity: -1)
    }

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

    func insert(_ item: T) {
        if capacity > 0,
           count >= capacity {
            return
        }
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.items.insert(item)
            }
        }
    }

    func set(_ items: [T]) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                if self.capacity > 0,
                   items.count >= self.capacity {
                    return
                }
                self.items.removeAll()
                for item in items {
                    self.items.insert(item)
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

    func takeAll() -> Set<T> {
        var allItems: Set<T>?
        queue.sync {
            allItems = self.items
            queue.async(flags: .barrier) { [weak self] in
                if let self = self {
                    self.items.removeAll()
                }
            }
        }
        return allItems ?? Set<T>()
    }
}
