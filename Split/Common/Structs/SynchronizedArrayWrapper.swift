//
//  SynchronizedArrayWrapper.swift
//  Split
//
//  Created by Javier on 26/07/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class SynchronizedArrayWrapper<T> {
    private var queue: DispatchQueue
    private var items: [T]

    var all: [T] {
        var allItems: [T]?
        queue.sync {
            allItems = items
        }
        return allItems!
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
        items = [T]()
    }

    func append(_ item: T) {
        queue.async(flags: .barrier) {
            self.items.append(item)
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }

    func append(_ items: [T]) {
        queue.async(flags: .barrier) {
            self.items.append(contentsOf: items)
        }
    }

    func fill(with newItems: [T]) {
        queue.async(flags: .barrier) {
            self.items.removeAll()
            self.items.append(contentsOf: newItems)
        }
    }

    func takeAll() -> [T] {
        var allItems: [T]!
        queue.sync {
            allItems = self.items
            queue.async(flags: .barrier) {
                self.items.removeAll()
            }
        }
        return allItems
    }
}
