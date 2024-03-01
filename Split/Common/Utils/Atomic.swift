//
//  Atomic.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

final class Atomic<T> {
//    private let queue = DispatchQueue(label: "split-atomic", target: DispatchQueue.general)
    private var currentValue: T

    private var lock = NSLock()

    init(_ value: T) {
        self.currentValue = value
    }

    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return self.currentValue
    }

    func mutate(_ transformation: (inout T) -> Void) {
        lock.lock()
        transformation(&self.currentValue)
        lock.unlock()
    }

    func mutate(_ transformation: (T, inout T) -> Void) {
        lock.lock()
        transformation(currentValue, &self.currentValue)
        lock.unlock()
    }

    func getAndSet(_ newValue: T) -> T {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = self.currentValue
        self.currentValue = newValue
        return oldValue
    }

    func set(_ newValue: T) {
        lock.lock()
        self.currentValue = newValue
        lock.unlock()
    }
}
//    var value: T {
//        return queue.sync { self.currentValue }
//    }
//
//    func mutate(_ transformation: (inout T) -> Void) {
//        queue.sync {
//            transformation(&self.currentValue)
//        }
//    }
//
//    func mutate(_ transformation: (T, inout T) -> Void) {
//        queue.sync {
//            transformation(currentValue, &self.currentValue)
//        }
//    }
//
//    func getAndSet(_ newValue: T) -> T {
//        var oldValue: T!
//        queue.sync {
//            oldValue = self.currentValue
//            self.currentValue = newValue
//        }
//        return oldValue
//    }
//
//    func set(_ newValue: T) {
//        queue.sync {
//            self.currentValue = newValue
//        }
//    }
//}

final class AtomicInt {
    private let queue = DispatchQueue(label: "split-atomic-int", target: DispatchQueue.general)
    private var curValue: Int
    private var lock = NSLock()

    init(_ value: Int) {
        self.curValue = value
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return curValue
    }

    func getAndAdd(_ addValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = self.curValue
        curValue+=addValue
        return oldValue
    }

    func addAndGet(_ addValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        curValue+=addValue
        let newValue = self.curValue
        return newValue
    }

    func set(_ newValue: Int) {
        lock.lock()
        defer { lock.unlock() }
        curValue = newValue
    }

    func getAndSet(_ newValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = curValue
        curValue = newValue
        return oldValue
    }

    func mutate(_ transformation: (inout Int) -> Void) {
        lock.lock()
        transformation(&self.curValue)
        lock.unlock()
    }
}


//    var value: Int {
//        return queue.sync { self.curValue }
//    }
//
//    func getAndAdd(_ addValue: Int) -> Int {
//        var oldValue: Int = 0
//        queue.sync {
//            oldValue = self.curValue
//            self.curValue+=addValue
//        }
//        return oldValue
//    }
//
//    func addAndGet(_ addValue: Int) -> Int {
//        var newValue: Int = 0
//        queue.sync {
//            self.curValue+=addValue
//            newValue = self.curValue
//        }
//        return newValue
//    }
//
//    func set(_ newValue: Int) {
//        queue.sync {
//            self.curValue = newValue
//        }
//    }
//
//    func getAndSet(_ newValue: Int) -> Int {
//        var oldValue: Int!
//        queue.sync {
//            oldValue = self.curValue
//            self.curValue = newValue
//        }
//        return oldValue
//    }
//
//    func mutate(_ transformation: (inout Int) -> Void) {
//        queue.sync {
//            transformation(&self.curValue)
//        }
//    }

//}
