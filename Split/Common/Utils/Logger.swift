//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

class Logger {

    private let queueName = "split.logger-queue"
    private var queue: DispatchQueue
    private let TAG: String = "SplitSDK"

    private var isVerboseEnabled = false
    private var isDebugEnabled = false

    enum Level: String {
        case verbose = "VERBOSE"
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    var isVerboseModeEnabled: Bool {
        set {
            queue.async(flags: .barrier) {
                self.isVerboseEnabled = newValue
            }
        }
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isVerboseEnabled
            }
            return isEnabled
        }
    }

    var isDebugModeEnabled: Bool {
        set {
            queue.async(flags: .barrier) {
                self.isDebugEnabled = newValue
            }
        }
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isDebugEnabled
            }
            return isEnabled
        }
    }

    static let shared: Logger = {
        let instance = Logger()
        return instance
    }()

    //Guarantee singleton instance
    private init() {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
    }

    private func log(level: Logger.Level, msg: String, _ ctx: Any ...) {

        if !isDebugModeEnabled && level == Logger.Level.debug {
            return
        }

        if !isVerboseModeEnabled && level == Logger.Level.verbose {
            return
        }

        if ctx.count == 0 {
            print(level.rawValue, self.TAG, msg)
        } else {
            print(level.rawValue, self.TAG, msg, ctx[0])
        }
    }

    static func v(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: Logger.Level.verbose, msg: message, context)
            : shared.log(level: Logger.Level.verbose, msg: message)
    }

    static func d(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: Logger.Level.debug, msg: message, context)
            : shared.log(level: Logger.Level.debug, msg: message)
    }

    static func i(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: Logger.Level.info, msg: message, context)
            : shared.log(level: Logger.Level.info, msg: message)
    }

    static func w(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: Logger.Level.warning, msg: message, context)
            : shared.log(level: Logger.Level.warning, msg: message)
    }

    static func e(_ message: String, _ context: Any ...) {
        context.count > 0
            ? shared.log(level: Logger.Level.error, msg: message, context)
            : shared.log(level: Logger.Level.error, msg: message)
    }
}
