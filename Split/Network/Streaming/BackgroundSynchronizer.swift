//
//  BackgroundSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 03/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

public class BackgroundSynchronizer {

    let splitsSyncWorker: BackgroundSynchronizer
    let mySegmentsSyncWorker: BackgroundSynchronizer
    let eventsRecorderWorker: RecorderWorker
    let impressionsRecorderWorker: RecorderWorker

    init(splitsSyncWorker: BackgroundSynchronizer, mySegmentsSyncWorker: BackgroundSynchronizer,
         eventsRecorderWorker: RecorderWorker, impressionsRecorderWorker: RecorderWorker) {
        self.splitsSyncWorker = splitsSyncWorker
        self.mySegmentsSyncWorker = mySegmentsSyncWorker
        self.eventsRecorderWorker = eventsRecorderWorker
        self.impressionsRecorderWorker = impressionsRecorderWorker
    }

    func executeSync() {
        let operationQueue = OperationQueue()

        operationQueue.addOperation {
            self.splitsSyncWorker.executeSync()
        }

        operationQueue.addOperation {
            self.mySegmentsSyncWorker.executeSync()
        }

        operationQueue.addOperation {
            self.eventsRecorderWorker.flush()
        }

        operationQueue.addOperation {
            self.impressionsRecorderWorker.flush()
        }
    }
}
