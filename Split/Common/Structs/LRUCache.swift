//
//  LRUCache.swift
//  Split
//
//  Created by Javier Avrudsky on 16/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class LRUCache<K: Hashable, E> {
    /// Elements queue tracks objects usage
    /// first element is last used
    /// last element is least used
    private var elementsQueue: [K]
    private var elements: [K: E]
    private let capacity: Int
    private let queue: DispatchQueue

    init(capacity: Int) {
        self.capacity = capacity
        self.elements = [K: E]()
        self.elementsQueue = [K]()
        self.elementsQueue.reserveCapacity(capacity)
        self.queue = DispatchQueue(label: "Split.LRUCache", attributes: .concurrent)
    }

    func set(_ element: E, for key: K) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.put(element, for: key)
        }
    }

    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.elements.removeAll()
        }
    }

    func element(for key: K) -> E? {
        var element: E?
        queue.sync {
            element = self.get(for: key)
        }
        return element
    }

    // Private function to avoid using self
    // Call this functions only from within queue closure
    private func put(_ element: E, for key: K) {
        // If element exists, remove from current position in the queue
        // to add last after
        if elements[key] != nil, let index = elementsQueue.firstIndex(where: { $0 == key }) {
            elementsQueue.remove(at: index)
        }

        // Add new element for key
        elements[key] = element

        // Check capacity before adding to avoid
        // reserving more memory
        if elements.count > capacity {
            // Remove least used
            let keyToRemove = elementsQueue.removeLast()
            elements.removeValue(forKey: keyToRemove)
        }

        // Add as last used
        elementsQueue.insert(key, at: 0)
    }

    // Same as above
    private func get(for key: K) -> E? {
        // Get element by key. Returns nil if not found
        guard let element = elements[key] else {
            return nil
        }
        // If element exists, move as last used
        if let index = elementsQueue.firstIndex(where: { $0 == key }) {
            moveFirst(index: index, key: key)
        }
        return element
    }

    private func moveFirst(index: Int, key: K) {
        self.queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.elementsQueue.remove(at: index)
            self.elementsQueue.insert(key, at: 0)
        }
    }
}
