//
//  DateProvider.swift
//  Logging
//
//  Created by Split SDK Team
//

import Foundation

/// Protocol for providing date/time functionality to the logging system
public protocol DateProvider {
    /// Returns current time in milliseconds since epoch
    func nowMillis() -> Int64
    
    /// Returns a formatted timestamp string for logging
    func nowLabel() -> String
}

/// Placeholder implementation that returns hardcoded values
/// This should be replaced by a real implementation from the consuming module
public struct PlaceholderDateProvider: DateProvider {
    public init() {}
    
    public func nowMillis() -> Int64 {
        return 0
    }
    
    public func nowLabel() -> String {
        return "00-00-0000 00:00:00.000"
    }
}
