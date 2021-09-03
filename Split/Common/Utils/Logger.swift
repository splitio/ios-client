//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

public enum LogLevel: String {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

public protocol SplitLogger {

    var isVerboseModeEnabled: Bool { get }
    var isDebugModeEnabled: Bool { get }
    func enableVerboseMode(_ enable: Bool)
    func enableDebugMode(_ enable: Bool)
    func log(level: LogLevel, msg: String, _ ctx: Any ...)
}

class Logger: SplitLogger {

    static var external: SplitLogger?

    private let queueName = "split.logger-queue"
    private var queue: DispatchQueue
    private let TAG: String = "SplitSDK"
    private var isVerboseEnabled = false
    private var isDebugEnabled = false

    var isVerboseModeEnabled: Bool {
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isVerboseEnabled
            }
            return isEnabled
        }
        set {
            queue.async(flags: .barrier) {
                self.isVerboseEnabled = newValue
            }
        }
    }

    private(set) var isDebugModeEnabled: Bool {
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isDebugEnabled
            }
            return isEnabled
        }
        set {
            queue.async(flags: .barrier) {
                self.isDebugEnabled = newValue
            }
        }
    }

    static let shared: SplitLogger = {
        return external ?? Logger()
    }()

    //Guarantee singleton instance
    private init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
    }

    func log(level: LogLevel, msg: String, _ ctx: Any ...) {

        if !isDebugModeEnabled && level == LogLevel.debug {
            return
        }

        if !isVerboseModeEnabled && level == LogLevel.verbose {
            return
        }

        if ctx.count == 0 {
            print(level.rawValue, self.TAG, msg)
        } else {
            print(level.rawValue, self.TAG, msg, ctx[0])
        }
    }

    func enableDebugMode(_ enable: Bool) {
        isDebugModeEnabled = enable
    }

    func enableVerboseMode(_ enable: Bool) {
        isVerboseModeEnabled = enable
    }

    static func v(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: LogLevel.verbose, msg: message, context)
            : shared.log(level: LogLevel.verbose, msg: message)
    }

    static func d(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: LogLevel.debug, msg: message, context)
            : shared.log(level: LogLevel.debug, msg: message)
    }

    static func i(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: LogLevel.info, msg: message, context)
            : shared.log(level: LogLevel.info, msg: message)
    }

    static func w(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: LogLevel.warning, msg: message, context)
            : shared.log(level: LogLevel.warning, msg: message)
    }

    static func e(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: LogLevel.error, msg: message, context)
            : shared.log(level: LogLevel.error, msg: message)
    }
}
