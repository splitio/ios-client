//
//  LogLevel.swift
//  Split
//
//  Created by Javier Avrudsky on 08-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

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
}
