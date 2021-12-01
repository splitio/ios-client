//
//  SplitFactory.swift
//  Split
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
public class DefaultSplitFactory: NSObject, SplitFactory {

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    private var defaultClient: SplitClient?
    private var defaultManager: SplitManager?
    private let filterBuilder = FilterBuilder()

    public var client: SplitClient {
        return defaultClient!
    }

    public var manager: SplitManager {
        return defaultManager!
    }

    public var version: String {
        return Version.sdk
    }

    init(apiKey: String,
         key: Key,
         config: SplitClientConfig,
         httpClient: HttpClient?,
         reachabilityChecker: HostReachabilityChecker?,
         testDatabase: SplitDatabase? = nil,
         notificationHelper: NotificationHelper? = nil) throws {
        super.init()

        let components = SplitComponentFactory(splitClientConfig: config,
                                               apiKey: apiKey,
                                               userKey: key.matchingKey)

        // Creating Events Manager first speeds up init process
        let eventsManager = components.getSplitEventsManager()

        //
        let databaseName = SplitDatabaseHelper.databaseName(apiKey: apiKey) ?? config.defaultDataFolder
        SplitDatabaseHelper.renameDatabaseFromLegacyName(name: databaseName, apiKey: apiKey)

        let storageContainer = try components.buildStorageContainer(databaseName: databaseName,
                                                                    testDatabase: testDatabase)

        LegacyStorageCleaner.deleteFiles(fileStorage: storageContainer.fileStorage, userKey: key.matchingKey)

        defaultManager = try components.getSplitManager()
        let restClient = try components.buildRestClient(
            httpClient: httpClient ?? DefaultHttpClient.shared,
            reachabilityChecker: reachabilityChecker ?? ReachabilityWrapper())

        let splitApiFacade = try components.buildSplitApiFacade(testHttpClient: httpClient)

        let synchronizer = try components.buildSynchronizer()
        let syncManager = try components.buildSyncManager(notificationHelper: notificationHelper)

        setupBgSync(config: config, apiKey: apiKey, userKey: key.matchingKey)

        defaultClient = DefaultSplitClient(config: config, key: key, apiFacade: splitApiFacade,
                                           storageContainer: storageContainer,
                                           synchronizer: synchronizer, eventsManager: eventsManager) { [weak self] in

            syncManager.stop()
            if let self = self, let manager = self.defaultManager as? Destroyable {
                manager.destroy()
            }
            eventsManager.stop()
            storageContainer.mySegmentsStorage.destroy()
            storageContainer.splitsStorage.destroy()
        }
        eventsManager.start()
        eventsManager.executorResources.client = defaultClient
        syncManager.start()
    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
    }
}
