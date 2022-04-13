//
//  TelemetryStatsRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 9-12-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class TelemetryStatsRecorderWorker: RecorderWorker {

    private let telemetryConsumer: TelemetryConsumer
    private let statsRecorder: HttpTelemetryStatsRecorder
    private let splitsStorage: SplitsStorage
    private let mySegmentsStorage: MySegmentsStorage

    init(telemetryStatsRecorder: HttpTelemetryStatsRecorder,
         telemetryConsumer: TelemetryConsumer,
         splitsStorage: SplitsStorage,
         mySegmentsStorage: MySegmentsStorage) {

        self.telemetryConsumer = telemetryConsumer
        self.statsRecorder = telemetryStatsRecorder
        self.splitsStorage = splitsStorage
        self.mySegmentsStorage = mySegmentsStorage
    }

    func flush() {
        if !statsRecorder.isEndpointAvailable() {
            Logger.d("Endpoint not reachable. Telemetry stats post will be delayed")
            return
        }

        let stats = buildRequestData()
        var sendCount = 1
        while !send(stats: stats) && sendCount < ServiceConstants.retryCount {
            sendCount+=1
            ThreadUtils.delay(seconds: ServiceConstants.retryTimeInSeconds)
        }
    }

    private func send(stats: TelemetryStats) -> Bool {
        do {
            _ = try statsRecorder.execute(stats)
            Logger.d("Telemetry stats posted successfully")
        } catch let error {
            Logger.e("Telemetry stats: \(String(describing: error))")
            return false
        }
        return true
    }

    private func buildRequestData() -> TelemetryStats {

        let storage = telemetryConsumer
        return TelemetryStats(lastSynchronization: storage.getLastSync(),
                              methodLatencies: storage.popMethodLatencies(),
                              methodExceptions: storage.popMethodExceptions(),
                              httpErrors: storage.popHttpErrors(),
                              httpLatencies: storage.popHttpLatencies(),
                              tokenRefreshes: storage.popTokenRefreshes(),
                              authRejections: storage.popAuthRejections(),
                              impressionsQueued: storage.getImpressionStats(type: .queued),
                              impressionsDeduped: storage.getImpressionStats(type: .deduped),
                              impressionsDropped: storage.getImpressionStats(type: .dropped),
                              splitCount: splitsStorage.getCount(),
                              segmentCount: mySegmentsStorage.getCount(),
                              segmentKeyCount: nil,
                              sessionLengthMs: storage.getSessionLength(),
                              eventsQueued: storage.getEventStats(type: .queued),
                              eventsDropped: storage.getEventStats(type: .dropped),
                              streamingEvents: storage.popStreamingEvents(),
                              tags: storage.popTags())
    }
}
