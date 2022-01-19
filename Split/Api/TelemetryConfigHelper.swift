//
//  TelemetryConfigHelper.swift
//  Split
//
//  Created by Javier Avrudsky on 04-Jan-2022.
//  Copyright © 2022 Split. All rights reserved.
//

// WARNING:
// This protocol is intended to be used while testing.
// That's why is only public for DEBUG mode

import Foundation
#if DEBUG
public protocol TelemetryConfigHelper {
    var shouldRecordTelemetry: Bool { get }
}
#else
protocol TelemetryConfigHelper {
    var shouldRecordTelemetry: Bool { get }
}
#endif

struct DefaultTelemetryConfigHelper: TelemetryConfigHelper {

    private static let kMaxValueProbability: Int = 1000
    private static let kAcceptanceRange: Double = 0.001
    private var shouldRecord
        = Double(Int.random(in: 0..<kMaxValueProbability + 1)) / Double(kMaxValueProbability) <= kAcceptanceRange

    var shouldRecordTelemetry: Bool {
        return shouldRecord
    }
}
