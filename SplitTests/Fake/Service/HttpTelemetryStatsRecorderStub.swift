//
//  HttpEventsRecorderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpTelemetryStatsRecorderStub: HttpTelemetryStatsRecorder {
    var queue: DispatchQueue?
    var endpointAvailable = true

    func isEndpointAvailable() -> Bool {
        return endpointAvailable
    }

    var statsSent: TelemetryStats?
    var errorOccurredCallCount = -1
    var executeCallCount = 0

    func execute(_ stats: TelemetryStats) throws {
        if let queue = queue {
            try queue.sync {
                try exec(stats)
            }
        } else {
            try exec(stats)
        }
    }

    private func exec(_ stats: TelemetryStats) throws {
        statsSent = stats
        executeCallCount += 1
        if errorOccurredCallCount >= executeCallCount {
            throw HttpError.unknown(code: -1, message: "something happend")
        }
    }
}
