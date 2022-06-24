//
//  ImpressionsMode.swift
//  Split
//
//  Created by Javier Avrudsky on 02/07/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum ImpressionsMode: String {
    case optimized = "OPTIMIZED"
    case debug = "DEBUG"
    case none = "NONE"

    func intValue() -> Int {
        switch self {
        case .optimized:
            return 0
        case .debug:
            return 1
        case .none:
            return 2
        }
    }
}
