//
//  TelemetryConfigHelperStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 11-Jan-2022.
//  Copyright © 2022 Split. All rights reserved.
//
import Foundation
@testable import Split

struct TelemetryConfigHelperStub: TelemetryConfigHelper {
    var value = false
    var shouldRecordTelemetry: Bool {
        return value
    }

    init(enabled: Bool) {
        self.value = enabled
    }
}
