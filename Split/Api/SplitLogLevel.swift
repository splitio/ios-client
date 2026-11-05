//  Created by Javier Avrudsky on 08-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.

import Foundation

#if SWIFT_PACKAGE || SPLIT_MODULAR
import Logging
#endif

public enum SplitLogLevel: String {

    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case none = "NONE"

    func order() -> Int {
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
    
    /// Maps SplitLogLevel to Logging's LogLevel
    func toLogLevel() -> LogLevel {
        switch self {
        case .verbose:
            return .verbose
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .none:
            return .none
        }
    }
    
    /// Creates SplitLogLevel from Logging's LogLevel
    static func from(_ logLevel: LogLevel) -> SplitLogLevel {
        switch logLevel {
        case .verbose:
            return .verbose
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
}
