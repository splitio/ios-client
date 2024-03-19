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

final class AtomicInt {
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
