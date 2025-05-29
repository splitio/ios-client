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

        // Visible for testing
        struct SyncItem: Codable {
            let apiKey: String
            var encryptionLevel: Int = 0
            var userKeys: [String: Int64] = [:] // UserKey, Timestamp
            var prefix: String?
        }

        // Visible for testing
        typealias BgSyncSchedule = [String: SyncItem]

        private let taskId = "io.split.bg-sync.task"
        private static let kTimeInterval = ServiceConstants.backgroundSyncPeriod
        static let kRegistrationExpiration = 3600 * 24 * 90 // 90 days

        var globalStorage: KeyValueStorage = GlobalSecureStorage.shared

        @objc public func register(
            dbKey: String, // prefix + apiKey
            prefix: String?,
            userKey: String,
            encryptionLevel: SplitEncryptionLevel = .none) {
            var syncMap = getSyncTaskMap()
            var syncItem = syncMap[dbKey] ?? SyncItem(apiKey: dbKey)
            syncItem.prefix = prefix
            syncItem.userKeys[userKey] = Date().unixTimestamp()
            syncItem.encryptionLevel = encryptionLevel.rawValue
            syncMap[dbKey] = syncItem
            globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
        }

        @objc public func unregister(dbKey: String, userKey: String) {
            var syncMap = getSyncTaskMap()
            if var item = syncMap[dbKey], item.userKeys[userKey] != nil {
                item.userKeys.removeValue(forKey: userKey)
                if !item.userKeys.isEmpty {
                    syncMap[dbKey] = item
                } else {
                    syncMap.removeValue(forKey: dbKey)
                }
                globalStorage.set(item: syncMap, for: .backgroundSyncSchedule)
            }
        }

        @objc public func unregisterAll() {
            globalStorage.remove(item: .backgroundSyncSchedule)
        }

        @available(iOSApplicationExtension, unavailable)
        @available(tvOSApplicationExtension, unavailable)
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
                            let pins = self.globalStorage.get(
                                item: .pinsConfig(item.apiKey),
                                type: [CredentialPin].self)
                            do {
                                // TODO: Create BGSyncExecutor using a factory to allow testing
                                let executor = try BackgroundSyncExecutor(
                                    prefix: item.prefix,
                                    apiKey: item.apiKey,
                                    userKeys: item.userKeys,
                                    serviceEndpoints: serviceEndpoints,
                                    pinnedCredentials: pins)
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
                    Logger.e(
                        "Couldn't register task for background execution, please check if the task " +
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
        private let mapKey: String
        private let userKeys: [String: Int64]
        private let mySegmentsFetcher: HttpMySegmentsFetcher

        init(
            prefix: String?,
            apiKey: String,
            userKeys: [String: Int64],
            serviceEndpoints: ServiceEndpoints? = nil,
            pinnedCredentials: [CredentialPin]?) throws {
            self.mapKey = SplitDatabaseHelper.buildDbKey(prefix: prefix, sdkKey: apiKey)
            self.userKeys = userKeys

            let cipherKey = SplitDatabaseHelper.currentEncryptionKey(for: mapKey)
            let encryptionLevel = SplitDatabaseHelper.currentEncryptionLevel(dbKey: mapKey)

            let databaseName = SplitDatabaseHelper.databaseName(
                prefix: prefix,
                apiKey: apiKey) ?? ServiceConstants.defaultDataFolder

            guard let dbHelper = CoreDataHelperBuilder.build(databaseName: databaseName) else {
                throw GenericError.couldNotCreateCache
            }

            guard let splitDatabase = try? SplitDatabaseHelper.openDatabase(
                dataFolderName: databaseName,
                cipherKey: cipherKey,
                encryptionLevel: encryptionLevel,
                dbHelper: dbHelper) else {
                throw GenericError.couldNotCreateCache
            }
            let splitsStorage = SplitDatabaseHelper.openPersistentSplitsStorage(database: splitDatabase)
            let generalInfoStorage = SplitDatabaseHelper.openGeneralInfoStorage(database: splitDatabase)
            let persistentRuleBasedSegmentsStorage = SplitDatabaseHelper.openPersistentRuleBasedSegmentsStorage(
                database: splitDatabase,
                generalInfoStorage: generalInfoStorage)
            let endpoints = serviceEndpoints ?? ServiceEndpoints.builder().build()
            let endpointFactory = EndpointFactory(
                serviceEndpoints: endpoints,
                apiKey: apiKey,
                splitsQueryString: generalInfoStorage.getSplitsFilterQueryString())

            var httpClient: HttpClient?
            if let pins = pinnedCredentials {
                let httpConfig = HttpSessionConfig.default
                httpConfig.pinChecker = DefaultTlsPinChecker(pins: pins)
                httpClient = DefaultHttpClient(configuration: httpConfig)
            }
            let restClient = DefaultRestClient(
                httpClient: httpClient ?? DefaultHttpClient.shared,
                endpointFactory: endpointFactory,
                reachabilityChecker: ReachabilityWrapper())

            let splitsFetcher = DefaultHttpSplitFetcher(
                restClient: restClient,
                syncHelper: DefaultSyncHelper(telemetryProducer: nil))

            self.mySegmentsFetcher = DefaultHttpMySegmentsFetcher(
                restClient: restClient,
                syncHelper: DefaultSyncHelper(telemetryProducer: nil))

            let bySetsFilter = splitsStorage.getBySetsFilter()
            let cacheExpiration = Int64(ServiceConstants.cacheExpirationInSeconds)
            let changeProcessor = DefaultSplitChangeProcessor(filterBySet: bySetsFilter)
            let ruleBasedSegmentChangeProcessor = DefaultRuleBasedSegmentChangeProcessor()
            self.splitsSyncWorker = BackgroundSplitsSyncWorker(
                splitFetcher: splitsFetcher,
                persistentSplitsStorage: splitsStorage,
                persistentRuleBasedSegmentsStorage: persistentRuleBasedSegmentsStorage,
                splitChangeProcessor: changeProcessor,
                ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
                cacheExpiration: cacheExpiration,
                splitConfig: SplitClientConfig())

            let impressionsRecorder
                = DefaultHttpImpressionsRecorder(
                    restClient: restClient,
                    syncHelper: DefaultSyncHelper(telemetryProducer: nil))
            let eventsRecorder
                = DefaultHttpEventsRecorder(
                    restClient: restClient,
                    syncHelper: DefaultSyncHelper(telemetryProducer: nil))

            self.eventsRecorderWorker =
                EventsRecorderWorker(
                    persistentEventsStorage:
                    SplitDatabaseHelper.openPersistentEventsStorage(database: splitDatabase),
                    eventsRecorder: eventsRecorder,
                    eventsPerPush: ServiceConstants.eventsPerPush)
            self.impressionsRecorderWorker = ImpressionsRecorderWorker(
                persistentImpressionsStorage: SplitDatabaseHelper
                    .openPersistentImpressionsStorage(database: splitDatabase),
                impressionsRecorder: impressionsRecorder,
                impressionsPerPush: ServiceConstants.impressionsQueueSize)

            self.splitDatabase = splitDatabase
        }

        func execute(operationQueue: OperationQueue) {
            operationQueue.addOperation {
                self.splitsSyncWorker.execute()
            }

            let mySegmentsStorage =
                SplitDatabaseHelper.openPersistentMySegmentsStorage(database: splitDatabase)
            let myLargeSegmentsStorage =
                SplitDatabaseHelper.openPersistentMyLargeSegmentsStorage(database: splitDatabase)

            operationQueue.addOperation {
                for (userKey, timestamp) in self.userKeys {
                    if self.isExpired(timestamp: timestamp) {
                        SplitBgSynchronizer.shared.unregister(dbKey: self.mapKey, userKey: userKey)
                        return
                    }

                    let mySegmentsSyncWorker = BackgroundMySegmentsSyncWorker(
                        userKey: userKey, mySegmentsFetcher: self.mySegmentsFetcher,
                        mySegmentsStorage: mySegmentsStorage,
                        myLargeSegmentsStorage: myLargeSegmentsStorage)
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

        private func buildMapKey(prefix: String?, apiKey: String) -> String {
            return "\(prefix ?? "")_\(apiKey)"
        }
    }
#endif
