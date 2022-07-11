//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

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
        return Logger()
    }()

    private init() {}

    private func log(level: SplitLogLevel, msg: String, _ ctx: Any ...) {

        if level.order() < self.level.order() {
            return
        }

        if ctx.count == 0 {
            printer.stdout(level.rawValue, tag, msg)
        } else {
            printer.stdout(level.rawValue, tag, msg, ctx[0])
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
