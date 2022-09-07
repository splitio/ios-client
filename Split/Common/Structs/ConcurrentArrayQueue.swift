//
//  ArrayBlockingQueue.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

class ConcurrentArrayQueue<T> {
    private let queue = DispatchQueue(label: "Split.ConcurrentArrayQueue",
                                      attributes: .concurrent)
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
                element = array[0]
                queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    self.array.remove(at: 0)
                }
            }
        }
        return element
    }
}
