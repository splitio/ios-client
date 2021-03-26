//
//  BackgroundSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 03/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import BackgroundTasks


@objc public class SplitBackgroundSynchronizer: NSObject {

    @objc public static let shared = SplitBackgroundSynchronizer()


    private let taskId = "io.split.bg-sync.task"
    private static let kTimeInterval = 15.0 * 60



    // keys = [ApiKey: UserKey]
    @objc public func schedule(keys: [String: String],
                               serviceEndpoints: ServiceEndpoints? = nil) {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskId,
                using: nil) { task in
                let operationQueue = OperationQueue()
                for (apiKey, userKey) in keys {
                    let executor = BackgroundSyncExecutor(apiKey: apiKey, userKey: userKey)
                    executor.execute(operationQueue: operationQueue)
                }

                task.expirationHandler = {
                    task.setTaskCompleted(success: false)
                    operationQueue.cancelAllOperations()
                }

                operationQueue.addBarrierBlock {
                    self.scheduleNextSync(taskId: self.taskId)
                    task.setTaskCompleted(success: true)
                }
            }
            scheduleNextSync(taskId: taskId)
        } else {
            Logger.w("Background sync only available for iOS 13+")
        }
    }

    private func scheduleNextSync(taskId: String) {
        if #available(iOS 13.0, *) {
            print("Scheduling \(taskId)")
            let request = BGAppRefreshTaskRequest(identifier: taskId)
            request.earliestBeginDate = Date(timeIntervalSinceNow: SplitBackgroundSynchronizer.kTimeInterval)

            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule Split background sync task: \(error)")
            }
        }
    }
}

struct BackgroundSyncExecutor {
    private var splitsSyncWorker: BackgroundSyncWorker?
    private var mySegmentsSyncWorker: BackgroundSyncWorker?
    private var eventsRecorderWorker: RecorderWorker?
    private var impressionsRecorderWorker: RecorderWorker?

    init(apiKey: String, userKey: String,
                serviceEndpoints: ServiceEndpoints? = nil) {

        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? ServiceConstants.defaultDataFolder

        guard let storageContainer = try? SplitFactoryHelper.buildStorageContainer(
                userKey: userKey, dataFolderName: dataFolderName, testDatabase: nil) else {
            return
        }

        let splitsFilterQueryString = storageContainer.splitDatabase
            .generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""

        let endpoints = serviceEndpoints ?? ServiceEndpoints.builder().build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: endpoints,
                                               apiKey: apiKey, userKey: userKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: ReachabilityWrapper())

        let splitsFetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                                    metricsManager: DefaultMetricsManager.shared)

        let mySegmentsFetcher: HttpMySegmentsFetcher
            = DefaultHttpMySegmentsFetcher(restClient: restClient, metricsManager: DefaultMetricsManager.shared)

        let cacheExpiration = Int64(ServiceConstants.cacheExpirationInSeconds)
        self.splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitsFetcher,
                                                           splitsStorage: storageContainer.splitsStorage,
                                                           splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                           cacheExpiration: cacheExpiration)

        self.mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
            userKey: userKey, mySegmentsFetcher: mySegmentsFetcher,
            mySegmentsStorage: storageContainer.mySegmentsStorage)

        let impressionsRecorder = DefaultHttpImpressionsRecorder(restClient: restClient)
        let eventsRecorder = DefaultHttpEventsRecorder(restClient: restClient)

        self.eventsRecorderWorker = EventsRecorderWorker(eventsStorage: storageContainer.eventsStorage,
                                                         eventsRecorder: eventsRecorder,
                                                         eventsPerPush: ServiceConstants.eventsPerPush)
        self.impressionsRecorderWorker = ImpressionsRecorderWorker(
            impressionsStorage: storageContainer.impressionsStorage,
            impressionsRecorder: impressionsRecorder,
            impressionsPerPush: ServiceConstants.impressionsQueueSize)
    }

    func execute(operationQueue: OperationQueue) {

        operationQueue.addOperation {
            self.splitsSyncWorker?.execute()
        }

        operationQueue.addOperation {
            self.mySegmentsSyncWorker?.execute()
        }

        operationQueue.addOperation {
            self.eventsRecorderWorker?.flush()
        }

        operationQueue.addOperation {
            self.impressionsRecorderWorker?.flush()
        }
    }
}
