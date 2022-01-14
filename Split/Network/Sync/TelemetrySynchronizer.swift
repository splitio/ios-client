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
    func start()
    func pause()
    func resume()
    func destroy()
}

class DefaultTelemetrySynchronizer: TelemetrySynchronizer {

    private let configRecorderWorker: RecorderWorker
    private let statsRecorderWorker: RecorderWorker
    private let periodicStatsRecorderWorker: PeriodicRecorderWorker
    private let syncQueue = DispatchQueue.global()

    init(configRecorderWorker: RecorderWorker,
         statsRecorderWorker: RecorderWorker,
         periodicStatsRecorderWorker: PeriodicRecorderWorker) {
        self.configRecorderWorker = configRecorderWorker
        self.statsRecorderWorker = statsRecorderWorker
        self.periodicStatsRecorderWorker = periodicStatsRecorderWorker
    }

    func synchronizeConfig() {
        syncQueue.async {
            self.configRecorderWorker.flush()
        }
    }

    func synchronizeStats() {
        syncQueue.async {
            self.statsRecorderWorker.flush()
        }
    }

    func start() {
        periodicStatsRecorderWorker.start()
    }

    func pause() {
        periodicStatsRecorderWorker.pause()
    }

    func resume() {
        periodicStatsRecorderWorker.resume()
    }

    func destroy() {
        periodicStatsRecorderWorker.stop()
        periodicStatsRecorderWorker.destroy()
    }

}
