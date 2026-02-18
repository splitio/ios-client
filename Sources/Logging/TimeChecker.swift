//  TimeChecker
//  Created by Split SDK Team.
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// Utility for checking and logging time intervals
public struct TimeChecker {
    
    #if swift(>=6.0)
        nonisolated(unsafe) private static var startTime: Int64 = 0
    #else
        private static var startTime: Int64 = 0
    #endif
    
    private static let tag = "[SPTPRF] "
    private static let showTimestamp = true
    private static let showSinceMsg = true
    
    public static func start(dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        startTime = provider.nowMillis()
        Logger.v("\(tag) TimeChecker started at: \(startTime)")
    }
    
    public static func logInterval(_ msg: String, dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        let now = provider.nowMillis()
        let interval = now - startTime
        Logger.v("\(tag) \(msg) \(formatTimestamp(now)) \(formatIntervalSinceStart(interval))")
    }
    
    public static func logTime(_ msg: String, dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        Logger.v("\(tag) \(msg) \(formatIntervalSinceStart(provider.nowMillis()))")
    }
    
    public static func logInterval(_ msg: String, startTime: Int64, dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        Logger.v("\(tag) \(msg) \(provider.nowMillis() - startTime) ms \(formatTimestamp(provider.nowMillis()))")
    }
    
    public static func formatInterval(_ interval: Int64) -> String {
        if !showSinceMsg {
            return "\(interval)"
        }
        return "Time since instanciation start \(interval) ms"
    }
    
    public static func formatIntervalSinceStart(_ interval: Int64) -> String {
        if !showSinceMsg {
            return "\(interval)"
        }
        return "\(interval) ms since instanciation start"
    }
    
    public static func formatTimestamp(_ now: Int64) -> String {
        if !showTimestamp {
            return ""
        }
        return "at \(now)"
    }
}
