//
//  TelemetrySynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol TelemetrySynchronizer {
    func synchronizeConfig()
    func synchronizeStats()
}

class DefaultTelemetrySynchronizer: TelemetrySynchronizer {

    private let configRecorderWorker: TelemetryConfigRecorderWorker
    private let telemetryStorage: TelemetryStorage
    private let splitClientConfig: SplitClientConfig
    private let syncQueue = DispatchQueue.global()

    init(splitClientConfig: SplitClientConfig,
         telemetryStorage: TelemetryStorage,
         configRecorderWorker: TelemetryConfigRecorderWorker) {

        self.splitClientConfig = splitClientConfig
        self.telemetryStorage = telemetryStorage
        self.configRecorderWorker = configRecorderWorker
    }

    func synchronizeConfig() {
        syncQueue.async {
            let
            self.configRecorderWorker.flush()
        }
    }

    func synchronizeStats() {
    }


}
