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
    private let kRetryTimeInSeconds = 0.5
    private let kRetryCount = 3

    init(configRecorder: HttpTelemetryConfigRecorder,
         telemetryConfig: TelemetryConfig) {
        self.configRecorder = configRecorder
        self.telemetryConfig = telemetryConfig
    }

    func flush() {
        var sendCount = 1
        while !send() && sendCount < kRetryCount {
            sendCount+=1
            ThreadUtils.delay(seconds: kRetryTimeInSeconds)
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
