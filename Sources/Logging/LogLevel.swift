//
//  LogLevel.swift
//  Logging
//
//  Created by Split SDK Team
//

import Foundation

/// Log level enumeration for the Logging module
public enum LogLevel: String {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case none = "NONE"
    
    /// Returns the numeric order of the log level (lower = more verbose)
    public func order() -> Int {
        switch self {
        case .verbose:
            return 0
        case .debug:
            return 1
        case .info:
            return 2
        case .warning:
            return 3
        case .error:
            return 4
        case .none:
            return 5
        }
    }
}
