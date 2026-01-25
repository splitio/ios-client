//
//  PersistenceBreaker.swift
//  Split
//
//

import Foundation
import Logging

/// Protocol for controlling persistence behavior in response to failures.
///
/// PersistenceBreaker centralizes "disable persistence for session" behavior.
/// After a persistence failure (e.g., CoreData save() error), storages can use
/// this to check if persistence is still allowed and to disable it on first failure.
///
protocol PersistenceBreaker {
    /// Returns true if persistence is currently enabled, false if disabled for session.
    var isPersistenceEnabled: Bool { get }
    
    /// Disables persistence for the remainder of the session.
    /// This operation is idempotent - calling multiple times has no additional effect.
    func disable()
}

/// Default implementation of PersistenceBreaker.
///
/// Usage:
///   let breaker = DefaultPersistenceBreaker()
///   if breaker.isPersistenceEnabled {
///       // attempt persistence...
///       // on failure: breaker.disable()
///   }
class DefaultPersistenceBreaker: PersistenceBreaker {
    
    private let lock = NSLock()
    private var _enabled = true
    
    var isPersistenceEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _enabled
    }
    
    func disable() {
        lock.lock()
        defer { lock.unlock() }
        
        // Idempotent: only disable once
        if _enabled {
            _enabled = false
            Logger.d("Targeting rules persistence disabled for session")
        }
    }
}

