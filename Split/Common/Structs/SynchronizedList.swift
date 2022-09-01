//
//  SynchronizedArrayWrapper.swift
//  Split
//
//  Created by Javier on 26/07/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class SynchronizedList<T> {
    private var queue: DispatchQueue
    private var items: [T]
    private var capacity: Int

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

    init(capacity: Int) {
        self.queue = DispatchQueue(label: "Split.SynchronizedList",
                                   target: .global())
        self.items = [T]()
        self.capacity = capacity
    }

    convenience init() {
        self.init(capacity: -1)
    }

    func append(_ item: T) {
        queue.sync {
            if capacity > -1,
               items.count >= self.capacity {
                return
            }
            items.append(item)
        }
    }

    func removeAll() {
        queue.sync {
            self.items.removeAll()
        }
    }

    func append(_ items: [T]) {
        queue.sync {
            if capacity > -1 {
                if items.count >= capacity {
                    return
                }
                let appendCount = capacity - self.items.count
                if appendCount < 1 {
                    return
                }
                self.items.append(contentsOf: items[0..<appendCount])
            } else {
                self.items.append(contentsOf: items)
            }
        }
    }

    func fill(with newItems: [T]) {
        queue.sync {
                items.removeAll()
                items.append(contentsOf: newItems)
        }
    }

    func takeAll() -> [T] {
        var allItems: [T]?
        queue.sync {
            allItems = self.items
            self.items.removeAll()
        }
        return allItems ?? []
    }

    func takeFirst() -> T? {
        var item: T?
        queue.sync {
            if items.count > 0 {
                item = self.items.first
                self.items.removeFirst()
            }
        }
        return item
    }
}
