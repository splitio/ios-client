//
//  Atomic.swift
//  PeriodicRecorderWorker
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Thread-safe wrapper for any value type
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
