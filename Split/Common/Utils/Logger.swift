//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation
import Logging

// Re-export Logger from Logging module for backward compatibility
// This allows existing Split code to continue using Logger.* without changes
typealias Logger = Logging.Logger

/// Split's implementation of DateProvider using Date+Utils extensions.
struct SplitDateProvider: DateProvider {
    func nowMillis() -> Int64 {
        Date.nowMillis()
    }

    func nowLabel() -> String {
        Date.nowLabel()
    }
}

// Initialize Logger with Split's DateProvider on first access
private let loggerInitializer: Void = {
    Logger.shared.dateProvider = SplitDateProvider()
}()

// Ensure logger is initialized when Split module loads
extension Logger {
    static func ensureInitialized() {
        _ = loggerInitializer
    }
}

// Use Logging's TimeChecker implementation.
// We keep these overloads to preserve Split's call sites AND to ensure the DateProvider is injected first.
typealias TimeChecker = Logging.TimeChecker

extension Logging.TimeChecker {
    static func start() {
        Logger.ensureInitialized()
        Self.start(dateProvider: nil)
    }

    static func logInterval(_ msg: String) {
        Logger.ensureInitialized()
        Self.logInterval(msg, dateProvider: nil)
    }

    static func logTime(_ msg: String) {
        Logger.ensureInitialized()
        Self.logTime(msg, dateProvider: nil)
    }

    static func logInterval(_ msg: String, startTime: Int64) {
        Logger.ensureInitialized()
        Self.logInterval(msg, startTime: startTime, dateProvider: nil)
    }
}

// LogPrinter and DefaultLogPrinter are now in the Logging module
// Re-export for backward compatibility
typealias LogPrinter = Logging.LogPrinter
typealias DefaultLogPrinter = Logging.DefaultLogPrinter

