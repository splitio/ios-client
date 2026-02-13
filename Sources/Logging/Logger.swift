//  Logger
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// Main logger class for the Logging module
public class Logger: @unchecked Sendable {
    public var printer: LogPrinter = DefaultLogPrinter()
    public var dateProvider: DateProvider = DefaultDateProvider()
    private let tag: String = "SplitSDK"
    
    public var level: LogLevel = .none
    
    public static let shared: Logger = {
        return Logger()
    }()
    
    private init() {}
    
    private func log(level: LogLevel, msg: String, _ ctx: Any ...) {
        if level.order() < self.level.order() {
            return
        }
        
        let timeLabel = dateProvider.nowLabel()
        if ctx.count == 0 {
            printer.stdout(timeLabel, level.rawValue, tag, msg)
        } else {
            printer.stdout(timeLabel, level.rawValue, tag, msg, ctx[0])
        }
    }
    
    public static func v(_ message: String, _ context: Any ...) {
        shared.log(level: .verbose, msg: message, context)
    }
    
    public static func d(_ message: String, _ context: Any ...) {
        shared.log(level: .debug, msg: message, context)
    }
    
    public static func i(_ message: String, _ context: Any ...) {
        shared.log(level: .info, msg: message, context)
    }
    
    public static func w(_ message: String, _ context: Any ...) {
        shared.log(level: .warning, msg: message, context)
    }
    
    public static func e(_ message: String, _ context: Any ...) {
        shared.log(level: .error, msg: message, context)
    }
}
