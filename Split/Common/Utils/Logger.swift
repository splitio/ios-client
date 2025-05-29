//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

enum TimeChecker {
    private static var startTime: Int64 = 0
    private static let tag = "[SPTPRF] "
    private static let showTimestamp = true
    private static let showSinceMsg = true
    static func start() {
        startTime = Date.nowMillis()
        Logger.v("\(tag) TimeChecker started at: \(startTime)")
    }

    static func logInterval(_ msg: String) {
        let now = Date.nowMillis()
        let interval = now - startTime
        Logger.v("\(tag) \(msg) \(formatTimestamp(now)) \(formatIntervalSinceStart(interval))")
    }

    static func logTime(_ msg: String) {
        Logger.v("\(tag) \(msg) \(formatIntervalSinceStart(Date.nowMillis()))")
    }

    static func logInterval(_ msg: String, startTime: Int64) {
        Logger.v("\(tag) \(msg) \(Date.nowMillis() - startTime) ms \(formatTimestamp(Date.nowMillis()))")
    }

    static func formatInterval(_ interval: Int64) -> String {
        if !showSinceMsg {
            return "\(interval)"
        }
        return "Time since instanciation start \(interval) ms"
    }

    static func formatIntervalSinceStart(_ interval: Int64) -> String {
        if !showSinceMsg {
            return "\(interval)"
        }
        return "\(interval) ms since instanciation start"
    }

    static func formatTimestamp(_ now: Int64) -> String {
        if !showTimestamp {
            return ""
        }
        return "at \(now)"
    }
}

// Protocol to enable testing for Logger class
protocol LogPrinter {
    func stdout(_ items: Any...)
}

class DefaultLogPrinter: LogPrinter {
    func stdout(_ items: Any...) {
        print(items)
    }
}

class Logger {
    var printer: LogPrinter = DefaultLogPrinter()
    private let tag: String = "SplitSDK"

    var level: SplitLogLevel = .none

    static let shared: Logger = {
        Logger()
    }()

    private init() {}

    private func log(level: SplitLogLevel, msg: String, _ ctx: Any ...) {
        if level.order() < self.level.order() {
            return
        }

        let timeLabel = Date.nowLabel()
        if ctx.isEmpty {
            printer.stdout(timeLabel, level.rawValue, tag, msg)
        } else {
            printer.stdout(timeLabel, level.rawValue, tag, msg, ctx[0])
        }
    }

    static func v(_ message: String, _ context: Any ...) {
        shared.log(level: .verbose, msg: message, context)
    }

    static func d(_ message: String, _ context: Any ...) {
        shared.log(level: .debug, msg: message, context)
    }

    static func i(_ message: String, _ context: Any ...) {
        shared.log(level: .info, msg: message, context)
    }

    static func w(_ message: String, _ context: Any ...) {
        shared.log(level: .warning, msg: message, context)
    }

    static func e(_ message: String, _ context: Any ...) {
        shared.log(level: .error, msg: message, context)
    }
}
