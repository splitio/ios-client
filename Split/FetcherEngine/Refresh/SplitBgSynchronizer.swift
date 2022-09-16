//
//  SplitBgSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 03/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import BackgroundTasks

@objc public class SplitBgSynchronizer: NSObject {

    @objc public static let shared = SplitBgSynchronizer()

    private struct SyncItem: Codable {
        let apiKey: String
        var userKeys: [String: Int64] = [:] // UserKey, Timestamp
    }

    private typealias BgSyncSchedule = [String: SyncItem]
    private let taskId = "io.split.bg-sync.task"
    private static let kTimeInterval = ServiceConstants.backgroundSyncPeriod
    static let kRegistrationExpiration = 3600 * 24 * 90 // 90 days

    var globalStorage: KeyValueStorage = GlobalSecureStorage.shared

    @objc public func register(apiKey: String, userKey: String) {
        var syncMap = getSyncTaskMap()
        var syncItem = syncMap[apiKey] ?? SyncItem(apiKey: apiKey)
        syncItem.userKeys[userKey] = Date().unixTimestamp()
        syncMap[apiKey] = syncItem
        globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
    }

    @objc public func unregister(apiKey: String, userKey: String) {
        var syncMap = getSyncTaskMap()
        if var item = syncMap[apiKey], item.userKeys[userKey] != nil {
            item.userKeys.removeValue(forKey: userKey)
            if item.userKeys.count > 0 {
                syncMap[apiKey] = item
            } else {
                syncMap.removeValue(forKey: apiKey)
            }
            globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
        }
    }

    @objc public func unregisterAll() {
        globalStorage.remove(item: .backgroundSyncSchedule)
    }

    @objc public func schedule(serviceEndpoints: ServiceEndpoints? = nil) {
        if #available(iOS 13.0, tvOS 13.0, macCatalyst 13.1, *) {
            let success = BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskId, using: nil) { task in

                let operationQueue = OperationQueue()
                let syncList = self.getSyncTaskMap()
                if syncList.isEmpty {
                    task.setTaskCompleted(success: true)
                    return
                }
                for item in syncList.values {
                    do {
                        let executor = try BackgroundSyncExecutor(apiKey: item.apiKey,
                                                                  userKeys: item.userKeys,
                                                                  serviceEndpoints: serviceEndpoints)
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
            if !success {
                Logger.e("Couldn't register task for background execution, please check if the task " +
                            "identifier \(taskId) was added to BGTaskSchedulerPermittedIdentifiers in your plist")
                return
            }
            scheduleNextSync(taskId: taskId)
        } else {
            Logger.w("Background sync only available for iOS 13+")
        }
    }

    private func scheduleNextSync(taskId: String) {
        if #available(iOS 13.0, tvOS 13.0, macCatalyst 13.1, *) {
            let request = BGAppRefreshTaskRequest(identifier: taskId)
            request.earliestBeginDate = Date(timeIntervalSinceNow: SplitBgSynchronizer.kTimeInterval)

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
    private let apiKey: String
    private let userKeys: [String: Int64]
    private let mySegmentsFetcher: HttpMySegmentsFetcher

    init(apiKey: String, userKeys: [String: Int64],
         serviceEndpoints: ServiceEndpoints? = nil) throws {

        self.apiKey = apiKey
        self.userKeys = userKeys

        let dataFolderName = SplitDatabaseHelper.databaseName(apiKey: apiKey) ?? ServiceConstants.defaultDataFolder
        guard let splitDatabase = try? SplitDatabaseHelper.openDatabase(dataFolderName: dataFolderName) else {
            throw GenericError.couldNotCreateCache
        }
        let splitsStorage = SplitDatabaseHelper.openPersistentSplitsStorage(database: splitDatabase)
        let endpoints = serviceEndpoints ?? ServiceEndpoints.builder().build()
        let  endpointFactory = EndpointFactory(serviceEndpoints: endpoints,
                                               apiKey: apiKey,
                                               splitsQueryString: splitsStorage.getFilterQueryString())

        let restClient = DefaultRestClient(httpClient: DefaultHttpClient.shared,
                                           endpointFactory: endpointFactory,
                                           reachabilityChecker: ReachabilityWrapper())

        let splitsFetcher = DefaultHttpSplitFetcher(restClient: restClient,
                                                    syncHelper: DefaultSyncHelper(telemetryProducer: nil))

        self.mySegmentsFetcher = DefaultHttpMySegmentsFetcher(restClient: restClient,
                                                              syncHelper: DefaultSyncHelper(telemetryProducer: nil))

        let cacheExpiration = Int64(ServiceConstants.cacheExpirationInSeconds)
        self.splitsSyncWorker = BackgroundSplitsSyncWorker(splitFetcher: splitsFetcher,
                                                           persistentSplitsStorage: splitsStorage,
                                                           splitChangeProcessor: DefaultSplitChangeProcessor(),
                                                           cacheExpiration: cacheExpiration,
                                                           splitConfig: SplitClientConfig())

        let impressionsRecorder
            = DefaultHttpImpressionsRecorder(restClient: restClient,
                                             syncHelper: DefaultSyncHelper(telemetryProducer: nil))
        let eventsRecorder
            = DefaultHttpEventsRecorder(restClient: restClient,
                                        syncHelper: DefaultSyncHelper(telemetryProducer: nil))

        self.eventsRecorderWorker =
            EventsRecorderWorker(eventsStorage: SplitDatabaseHelper.openEventsStorage(database: splitDatabase),
                                                         eventsRecorder: eventsRecorder,
                                                         eventsPerPush: ServiceConstants.eventsPerPush)
        self.impressionsRecorderWorker = ImpressionsRecorderWorker(
            impressionsStorage: SplitDatabaseHelper.openImpressionsStorage(database: splitDatabase),
            impressionsRecorder: impressionsRecorder,
            impressionsPerPush: ServiceConstants.impressionsQueueSize)

        self.splitDatabase = splitDatabase
    }

    func execute(operationQueue: OperationQueue) {

        operationQueue.addOperation {
            self.splitsSyncWorker.execute()
        }

        let mySegmentsStorage =
            SplitDatabaseHelper.openPersistentMySegmentsStorage(database: self.splitDatabase)
        operationQueue.addOperation {
            for (userKey, timestamp) in self.userKeys {
                if self.isExpired(timestamp: timestamp) {
                    SplitBgSynchronizer.shared.unregister(apiKey: self.apiKey, userKey: userKey)
                    return
                }

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

    func isExpired(timestamp: Int64) -> Bool {
        return Date().unixTimestamp() - timestamp > SplitBgSynchronizer.kRegistrationExpiration
    }
}
#endif
