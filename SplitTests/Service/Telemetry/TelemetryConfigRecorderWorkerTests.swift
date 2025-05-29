//
//  configRecorderWorkerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class TelemetryConfigRecorderWorkerTests: XCTestCase {
    var worker: TelemetryConfigRecorderWorker!
    var configRecorder: HttpTelemetryConfigRecorderStub!

    override func setUp() {
        configRecorder = HttpTelemetryConfigRecorderStub()
        worker = TelemetryConfigRecorderWorker(
            telemetryConfigRecorder: configRecorder,
            splitClientConfig: SplitClientConfig(),
            telemetryConsumer: TelemetryStorageStub())
    }

    func testSendSuccess() {
        worker.flush()

        XCTAssertEqual(1, configRecorder.executeCallCount)
        XCTAssertNotNil(configRecorder.configSent)
    }

    func testFailedAttemptLimit() {
        configRecorder.errorOccurredCallCount = 3

        worker.flush()

        XCTAssertEqual(3, configRecorder.executeCallCount)
    }

    func testFailedAttemptLimitExceded() {
        configRecorder.errorOccurredCallCount = 10

        worker.flush()
        sleep(1) // To pass in GHA
        XCTAssertEqual(3, configRecorder.executeCallCount)
    }

    func createTelemetryConfig() -> TelemetryConfig {
        let rates = TelemetryRates(
            splits: 1,
            mySegments: 2,
            impressions: 3,
            events: 4,
            telemetry: 5)
        let urls = TelemetryUrlOverrides(
            sdk: true,
            events: true,
            auth: true,
            stream: true,
            telemetry: true)

        return TelemetryConfig(
            streamingEnabled: true,
            rates: rates,
            urlOverrides: urls,
            impressionsQueueSize: 100,
            eventsQueueSize: 200,
            impressionsMode: 0,
            impressionsListenerEnabled: false,
            httpProxyDetected: false,
            activeFactories: 10,
            redundantFactories: 2,
            timeUntilReady: 10,
            timeUntilReadyFromCache: 5,
            nonReadyUsages: 2,
            integrations: ["i1"],
            tags: ["tag1"])
    }
}
