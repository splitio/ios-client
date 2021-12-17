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

    init(_ params: SplitFactoryParams) throws {
        super.init()

        let components = SplitComponentFactory(splitClientConfig: params.config,
                                               apiKey: params.apiKey,
                                               userKey: params.key.matchingKey)

        // Creating Events Manager first speeds up init process
        let eventsManager = components.getSplitEventsManager()

        //
        let databaseName = SplitDatabaseHelper.databaseName(apiKey: params.apiKey) ?? params.config.defaultDataFolder
        SplitDatabaseHelper.renameDatabaseFromLegacyName(name: databaseName, apiKey: params.apiKey)

        let storageContainer = try components.buildStorageContainer(databaseName: databaseName,
                                                                    telemetryStorage: params.telemetryStorage,
                                                                    testDatabase: params.testDatabase)

        LegacyStorageCleaner.deleteFiles(fileStorage: storageContainer.fileStorage, userKey: params.key.matchingKey)

        defaultManager = try components.getSplitManager()
        let restClient = try components.buildRestClient(
            httpClient: params.httpClient ?? DefaultHttpClient.shared,
            reachabilityChecker: params.reachabilityChecker ?? ReachabilityWrapper())

        let splitApiFacade = try components.buildSplitApiFacade(testHttpClient: params.httpClient)

        let synchronizer = try components.buildSynchronizer()
        let syncManager = try components.buildSyncManager(notificationHelper: params.notificationHelper)

        setupBgSync(config: params.config, apiKey: params.apiKey, userKey: params.key.matchingKey)

        defaultClient = DefaultSplitClient(config: params.config, key: params.key, apiFacade: splitApiFacade,
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
        defaultClient?.on(event: .sdkReady) {
            DispatchQueue.global().async {
                params.telemetryStorage?.recordTimeUntilReady(params.initStopwatch.interval())
            }
        }

        defaultClient?.on(event: .sdkReady) {
            DispatchQueue.global().async {
                params.telemetryStorage?.recordTimeUntilReadyFromCache(params.initStopwatch.interval())
            }
        }
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
