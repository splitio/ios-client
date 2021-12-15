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

    private let configRecorderWorker: RecorderWorker
    private let statsRecorderWorker: RecorderWorker
    private let syncQueue = DispatchQueue.global()

    init(configRecorderWorker: RecorderWorker,
         statsRecorderWorker: RecorderWorker) {
        self.configRecorderWorker = configRecorderWorker
        self.statsRecorderWorker = statsRecorderWorker
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
}
