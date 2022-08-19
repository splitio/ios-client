//
//  ArrayBlockingQueue.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

/// A thread-safe array.
class ConcurrentArrayQueue<T> {
    private let queue = DispatchQueue(label: "io.Split.Structs.ArraySerialBlockingQueue", attributes: .concurrent)
    private var array = [T]()
    private var firstAppend = true

    // Adds a new element at the end of the array.
    func append( _ element: T) {
        queue.async(flags: .barrier) { [weak self] in
            if let self = self {
                self.array.append(element)
            }
        }
    }

    // Removes and returns the element at the specified position.
    func take() -> T? {
        var element: T?
        queue.sync {
            if !array.isEmpty {
                queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    element = self.array.remove(at: 0)
                }
            }
        }
        return element
    }
}
