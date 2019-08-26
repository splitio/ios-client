//
//  ArrayBlockingQueue.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

/// A thread-safe array.
class SynchronizedArrayQueue<T> {
    fileprivate let queue = DispatchQueue(label: "io.Split.Structs.ArraySerialBlockingQueue", attributes: .concurrent)
    fileprivate var array = [T]()
    fileprivate var firstAppend = true
}

// MARK: - Mutable
extension SynchronizedArrayQueue {

    // Adds a new element at the end of the array.
    func append( _ element: T) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }

    // Removes and returns the element at the specified position.
    func take(completion: ((T) -> Void)? = nil) {
        queue.sync {
            guard !array.isEmpty else {
                return
            }

            let element = self.array.remove(at: 0)

            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
}
