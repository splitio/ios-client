//
//  Spec.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class Spec {
    #if swift(>=6.0)
        nonisolated(unsafe) static var flagsSpec = "1.3"
    #else
        static var flagsSpec = "1.3"
    #endif
}
