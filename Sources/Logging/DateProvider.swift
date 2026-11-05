//  DateProvider
//  Created by Split SDK Team.
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// Protocol for providing date/time functionality to the logging system
public protocol DateProvider {
    /// Returns current time in milliseconds since epoch
    func nowMillis() -> Int64
    
    /// Returns a formatted timestamp string for logging
    func nowLabel() -> String
}

/// Default implementation that uses Foundation's Date
public struct DefaultDateProvider: DateProvider {
    public init() {}

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss.SSS"
        return formatter
    }()

    public func nowMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    public func nowLabel() -> String {
        return Self.formatter.string(from: Date())
    }
}
