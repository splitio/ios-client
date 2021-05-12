//
//  BlockingQueue.swift
//  Split
//
//  Created by Javier Avrudsky on 06/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum BlockingQueueError: Error {
    case hasBeenInterrupted
    case noElementAvailable
}

class GenericBlockingQueue<Item> {
    private var elements: [Item]
    private let dispatchQueue: DispatchQueue
    private let semaphore: DispatchSemaphore
    private var isInterrupted = false
    init() {
        dispatchQueue = DispatchQueue(label: "split-blocking-queue", attributes: .concurrent)
        semaphore = DispatchSemaphore(value: 0)
        elements = [Item]()
    }

    func add(_ item: Item) {
        dispatchQueue.async(flags: .barrier) {
            self.elements.append(item)
            self.semaphore.signal()
        }
    }

    func take() throws -> Item {
        var item: Item?
        self.semaphore.wait()
        try dispatchQueue.sync {
            if self.isInterrupted {
                throw BlockingQueueError.hasBeenInterrupted
            }
            item = elements[0]
            self.elements.removeFirst()
        }
        guard let foundItem = item else {
            throw BlockingQueueError.noElementAvailable
        }
        return foundItem
    }

    func interrupt() {
        dispatchQueue.async(flags: .barrier) {
            self.isInterrupted = true
            self.semaphore.signal()
        }
    }
}

// Protocol to allow mocking
protocol InternalEventBlockingQueue {
    func add(_ item: SplitInternalEvent)
    func take() throws -> SplitInternalEvent
    func interrupt()
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

    func interrupt() {
        blockingQueue.interrupt()
    }
}
