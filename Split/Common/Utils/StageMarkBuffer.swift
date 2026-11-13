//
//  StageMarkBuffer.swift
//  Split
//
//  FME-22007: per-factory in-memory buffer of monotonic stage marks.
//

import Foundation

/// Collects (name, uptime nanoseconds) marks. Uses its own lock, never one of the measured path.
final class StageMarkBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = [(name: String, nanos: UInt64)]()

    func record(_ name: String, _ nanos: UInt64) {
        lock.lock()
        storage.append((name: name, nanos: nanos))
        lock.unlock()
    }

    var marks: [(name: String, nanos: UInt64)] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    var sink: @Sendable (String, UInt64) -> Void {
        return { [self] name, nanos in self.record(name, nanos) }
    }
}
