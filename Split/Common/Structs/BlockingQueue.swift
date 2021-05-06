//
//  BlockingQueue.swift
//  Split
//
//  Created by Javier Avrudsky on 06/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class GenericBlockingQueue<Item> {
    private var elements: [Item]
    private let dispatchQueue: DispatchQueue
    private let semaphore: DispatchSemaphore
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

    func take() -> Item {
        var item: Item!
        self.semaphore.wait()
        dispatchQueue.sync {
            item = elements[0]
            self.elements.removeFirst()
        }
        return item
    }
}

// Protocol to allow mocking
protocol InternalEventBlockingQueue {
    func add(_ item: SplitInternalEvent)

    func take() -> SplitInternalEvent
}

class DefaultInternalEventBlockingQueue: InternalEventBlockingQueue {
    let blockingQueue = GenericBlockingQueue<SplitInternalEvent>()
    func add(_ item: SplitInternalEvent) {
        print("Add: \(item)")
        blockingQueue.add(item)
    }

    func take() -> SplitInternalEvent {
        let value =  blockingQueue.take()
        print("Take: \(value)")
        return value
    }
}
