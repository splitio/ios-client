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

    private var splitsSyncWorker: BackgroundSyncWorker?
    private var mySegmentsSyncWorker: BackgroundSyncWorker?
    private var eventsRecorderWorker: RecorderWorker?
    private var impressionsRecorderWorker: RecorderWorker?
    private static let kTaskIdentifier = "io.split.bg-sync.task"
    private static let kTimeInterval = 15.0 * 60

    func create(apiKey: String, userKey: Key) {

        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? ServiceConstants.defaultDataFolder

        guard let storageContainer = try? SplitFactoryHelper.buildStorageContainer(
                userKey: userKey.matchingKey, dataFolderName: dataFolderName, testDatabase: nil) else {
            return
        }

        let splitsFilterQueryString = storageContainer.splitDatabase
            .generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""

        let endpointBuilder = ServiceEndpoints.builder()
        if true { // DEBUG
            let kSdkEndpointStaging = "https://sdk.split-stage.io/api"
            let KEventsEndpointStaging = "https://events.split-stage.io/api"
            _ = endpointBuilder
                .set(sdkEndpoint: kSdkEndpointStaging)
                .set(eventsEndpoint: KEventsEndpointStaging)
        }

        let  endpointFactory = EndpointFactory(serviceEndpoints: endpointBuilder.build(),
                                               apiKey: apiKey, userKey: userKey.matchingKey,
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
            userKey: userKey.matchingKey, mySegmentsFetcher: mySegmentsFetcher,
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

    @objc public func schedule(apiKey: String, userKey: Key) {
        if #available(iOS 13.0, *) {
            create(apiKey: apiKey, userKey: userKey)
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: SplitBackgroundSynchronizer.kTaskIdentifier,
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
            scheduleNextSync()
        } else {
            Logger.w("Background sync only available for iOS 13+")
        }
    }

    private func syncOperation() -> OperationQueue {
        scheduleNextSync()
        let operationQueue = OperationQueue()

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
        return operationQueue
    }

    private func scheduleNextSync() {
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: SplitBackgroundSynchronizer.kTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: SplitBackgroundSynchronizer.kTimeInterval)

            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule Split background sync task: \(error)")
            }
        }
    }
}
