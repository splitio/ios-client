//
//  Atomic.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

public final class Atomic<T>: @unchecked Sendable {
    private var currentValue: T

    private var lock = NSLock()

    public init(_ value: T) {
        self.currentValue = value
    }

    public var value: T {
        lock.lock()
        defer { lock.unlock() }
        return self.currentValue
    }

    public func mutate(_ transformation: (inout T) -> Void) {
        lock.lock()
        transformation(&self.currentValue)
        lock.unlock()
    }

    public func mutate(_ transformation: (T, inout T) -> Void) {
        lock.lock()
        transformation(currentValue, &self.currentValue)
        lock.unlock()
    }

    public func getAndSet(_ newValue: T) -> T {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = self.currentValue
        self.currentValue = newValue
        return oldValue
    }

    public func set(_ newValue: T) {
        lock.lock()
        self.currentValue = newValue
        lock.unlock()
    }
}

public final class AtomicInt: @unchecked Sendable {
    private var curValue: Int
    private var lock = NSLock()

    public init(_ value: Int) {
        self.curValue = value
    }

    public var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return curValue
    }

    public func getAndAdd(_ addValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = self.curValue
        curValue+=addValue
        return oldValue
    }

    public func addAndGet(_ addValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        curValue+=addValue
        let newValue = self.curValue
        return newValue
    }

    public func set(_ newValue: Int) {
        lock.lock()
        defer { lock.unlock() }
        curValue = newValue
    }

    public func getAndSet(_ newValue: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let oldValue = curValue
        curValue = newValue
        return oldValue
    }

    public func mutate(_ transformation: (inout Int) -> Void) {
        lock.lock()
        transformation(&self.curValue)
        lock.unlock()
    }
}
