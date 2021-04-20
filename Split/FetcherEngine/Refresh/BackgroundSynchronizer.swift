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

    private struct SyncItem: Codable {
        let apiKey: String
        var userKeys: Set<String> = Set()
    }

    private typealias BgSyncSchedule = [String: SyncItem]
    private let taskId = "io.split.bg-sync.task"
    private static let kTimeInterval = ServiceConstants.backgroundSyncPeriod
    var globalStorage: KeyValueStorage = GlobalSecureStorage.shared

    @objc public func register(apiKey: String, userKey: String) {
        var syncMap = getSyncTaskMap()
        var syncItem = syncMap[apiKey] ?? SyncItem(apiKey: apiKey)
        syncItem.userKeys.insert(userKey)
        syncMap[apiKey] = syncItem
        globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
    }

    @objc public func unregister(apiKey: String, userKey: String) {
        let syncMap = getSyncTaskMap()
        if var item = syncMap[apiKey], item.userKeys.contains(userKey) == true {
            item.userKeys.remove(userKey)
            globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
        }
    }

    @objc public func unregisterAll() {
        globalStorage.remove(item: .backgroundSyncSchedule)
    }

    // keys = [ApiKey: UserKey]
    @objc public func schedule(serviceEndpoints: ServiceEndpoints? = nil) {
        if #available(iOS 13.0, *) {

            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskId, using: nil) { task in
                let syncList = self.getSyncTaskMap()
                if syncList.count == 0 {
                    return
                }
                let operationQueue = OperationQueue()
                for item in syncList.values {
                    do {
                        let executor = try BackgroundSyncExecutor(apiKey: item.apiKey, userKeys: Array(item.userKeys))
                        executor.execute(operationQueue: operationQueue)
                    } catch {
                        Logger.d("Could not create background synchronizer for api key: \(item.apiKey)")
                    }
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

    private func getSyncTaskMap() -> [String: SyncItem] {
        return globalStorage.get(item: .backgroundSyncSchedule, type: BgSyncSchedule.self) ?? [String: SyncItem]()
    }
}

struct BackgroundSyncExecutor {
    private let splitDatabase: SplitDatabase
    private let splitsSyncWorker: BackgroundSyncWorker
    private let eventsRecorderWorker: RecorderWorker
    private let impressionsRecorderWorker: RecorderWorker
    private let userKeys: [String]
    private let mySegmentsFetcher: HttpMySegmentsFetcher

    init(apiKey: String, userKeys: [String],
         serviceEndpoints: ServiceEndpoints? = nil) throws {

        self.userKeys = userKeys
        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? ServiceConstants.defaultDataFolder

        // Using "" as key because My Segment storage property will not be used
        // TODO: Update storage container when using multipley key for a client
        guard let storageContainer = try? SplitFactoryHelper.buildStorageContainer(
                userKey: "", dataFolderName: dataFolderName, testDatabase: nil) else {
            throw GenericError.unknown(message: "Could not create storage container")
        }

        splitDatabase = storageContainer.splitDatabase

        let splitsFilterQueryString = storageContainer.splitDatabase
            .generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""

        let endpoints = serviceEndpoints ?? ServiceEndpoints.builder().build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: endpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsFilterQueryString)

        let restClient = DefaultRestClient(httpClient: DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: ReachabilityWrapper())

        let splitsFetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                                    metricsManager: DefaultMetricsManager.shared)

        self.mySegmentsFetcher = DefaultHttpMySegmentsFetcher(restClient: restClient,
                                                              metricsManager: DefaultMetricsManager.shared)

        let cacheExpiration = Int64(ServiceConstants.cacheExpirationInSeconds)
        self.splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitsFetcher,
                                                           splitsStorage: storageContainer.splitsStorage,
                                                           splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                           cacheExpiration: cacheExpiration)

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
            self.splitsSyncWorker.execute()
        }

        operationQueue.addOperation {
            for userKey in self.userKeys {
                let persistentMySegmentsStorage =
                    DefaultPersistentMySegmentsStorage(userKey: userKey,
                                                       database: self.splitDatabase)
                let mySegmentsStorage =
                    DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage)

                let mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
                    userKey: userKey, mySegmentsFetcher: self.mySegmentsFetcher,
                    mySegmentsStorage: mySegmentsStorage)
                mySegmentsSyncWorker.execute()
            }
        }

        operationQueue.addOperation {
            self.eventsRecorderWorker.flush()
        }

        operationQueue.addOperation {
            self.impressionsRecorderWorker.flush()
        }
    }
}
