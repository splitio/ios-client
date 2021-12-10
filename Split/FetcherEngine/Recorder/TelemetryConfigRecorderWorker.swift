//
//  TelemetryConfigRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class TelemetryConfigRecorderWorker: RecorderWorker {

    private let configRecorder: HttpTelemetryConfigRecorder
    private let telemetryConfig: TelemetryConfig

    init(configRecorder: HttpTelemetryConfigRecorder,
         telemetryConfig: TelemetryConfig) {
        self.configRecorder = configRecorder
        self.telemetryConfig = telemetryConfig
    }

    func flush() {
        var sendCount = 1
        while !send() && sendCount < ServiceConstants.retryCount {
            sendCount+=1
            ThreadUtils.delay(seconds: ServiceConstants.retryTimeInSeconds)
        }
    }

    private func send() -> Bool {
        do {
            _ = try configRecorder.execute(telemetryConfig)
            Logger.d("Telemetry config posted successfully")
        } catch let error {
            Logger.e("Telemetry config: \(String(describing: error))")
            return false
        }
        return true
    }
}
