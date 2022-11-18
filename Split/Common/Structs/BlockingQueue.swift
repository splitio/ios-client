//
//  BlockingQueue.swift
//  Split
//
//  Created by Javier Avrudsky on 06/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum BlockingQueueError: Error {
    case hasBeenStopped
    case noElementAvailable
}

class GenericBlockingQueue<Item> {
    private var elements: [Item]
    private let dispatchQueue: DispatchQueue
    private let semaphore: DispatchSemaphore
    private var isStopped = false
    init() {
        dispatchQueue = DispatchQueue(label: "Split.GenericBlockingQueue",
                                      attributes: .concurrent)
        semaphore = DispatchSemaphore(value: 0)
        elements = [Item]()
    }

    func add(_ item: Item) {
        dispatchQueue.async(flags: .barrier) { [weak self] in
            if let self = self {
                if self.isStopped { return }
                self.elements.append(item)
                self.semaphore.signal()
            }
        }
    }

    func take() throws -> Item {
        var item: Item?
        // Checks if stopped before waiting
        try checkIfStopped()
        self.semaphore.wait()
        try dispatchQueue.sync(flags: .barrier) {
            // Checks if thread was awaked by stop or interruption
            try checkIfStopped()
            if elements.count > 0 {
                item = elements.removeFirst()
            }
        }
        guard let foundItem = item else {
            throw BlockingQueueError.noElementAvailable
        }
        return foundItem
    }

    func stop() {
        dispatchQueue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.isStopped = true
                self.elements.removeAll()
                self.semaphore.signal()
            }
        }
    }

    // Use this function within the queue
    private func checkIfStopped() throws {
        if self.isStopped {
            throw BlockingQueueError.hasBeenStopped
        }
    }
}

// Protocol to allow mocking
protocol InternalEventBlockingQueue {
    func add(_ item: SplitInternalEvent)
    func take() throws -> SplitInternalEvent
    func stop()
}

class DefaultInternalEventBlockingQueue: InternalEventBlockingQueue {
    let blockingQueue = GenericBlockingQueue<SplitInternalEvent>()
    func add(_ item: SplitInternalEvent) {
        blockingQueue.add(item)
    }

    func take() throws -> SplitInternalEvent {
        let value =  try blockingQueue.take()
        return value
    }

    func stop() {
        blockingQueue.stop()
    }
}
