//
//  BackgroundSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 03/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import BackgroundTasks

class BackgroundSynchronizer {

    private let splitsSyncWorker: BackgroundSyncWorker
    private let mySegmentsSyncWorker: BackgroundSyncWorker
    private let eventsRecorderWorker: RecorderWorker
    private let impressionsRecorderWorker: RecorderWorker
    private let kTaskIdentifier = "io.split.bg-sync.task"

    init(splitsSyncWorker: BackgroundSyncWorker, mySegmentsSyncWorker: BackgroundSyncWorker,
         eventsRecorderWorker: RecorderWorker, impressionsRecorderWorker: RecorderWorker) {
        self.splitsSyncWorker = splitsSyncWorker
        self.mySegmentsSyncWorker = mySegmentsSyncWorker
        self.eventsRecorderWorker = eventsRecorderWorker
        self.impressionsRecorderWorker = impressionsRecorderWorker
    }

    func schedule() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: kTaskIdentifier,
                using: nil) { task in
                let operationQueue = self.syncOperation()
                task.expirationHandler = {
                    task.setTaskCompleted(success: false)
                    operationQueue.cancelAllOperations()
                }

                operationQueue.addBarrierBlock {
                    task.setTaskCompleted(success: true)
                }
            }
        } else {
            Logger.w("Backround sync only available for iOS 13+")
        }
    }

    private func syncOperation() -> OperationQueue {
        let operationQueue = OperationQueue()

        operationQueue.addOperation {
            self.splitsSyncWorker.execute()
        }

        operationQueue.addOperation {
            self.mySegmentsSyncWorker.execute()
        }

        operationQueue.addOperation {
            self.eventsRecorderWorker.flush()
        }

        operationQueue.addOperation {
            self.impressionsRecorderWorker.flush()
        }
        return operationQueue
    }
}
