//  TimeChecker
//  Created by Split SDK Team.
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// Utility for checking and logging time intervals. One instance per factory.
public struct TimeChecker {

    public let factoryId: Int
    public let startTime: Int64

    private static let tag = "[SPTPRF]"
    private static let showTimestamp = true
    private static let showSinceMsg = true

    public init(factoryId: Int, startTime: Int64) {
        self.factoryId = factoryId
        self.startTime = startTime
    }

    private var factoryTag: String {
        return "\(TimeChecker.tag)[F\(factoryId)] "
    }

    public func logInterval(_ msg: String, dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        let now = provider.nowMillis()
        let interval = now - startTime
        Logger.v("\(factoryTag) \(msg) \(TimeChecker.formatTimestamp(now)) "
                 + "\(TimeChecker.formatIntervalSinceStart(interval))")
    }

    public func logInterval(_ msg: String, since start: Int64, dateProvider: DateProvider? = nil) {
        let provider = dateProvider ?? Logger.shared.dateProvider
        let now = provider.nowMillis()
        Logger.v("\(factoryTag) \(msg) \(now - start) ms \(TimeChecker.formatTimestamp(now))")
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
