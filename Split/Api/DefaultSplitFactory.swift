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

    private var clientManager: SplitClientManager?

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    private var defaultManager: SplitManager?
    private let filterBuilder = FilterBuilder()

    public var client: SplitClient {
        // TODO: Check this line
        return clientManager!.defaultClient!
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
        _ = try components.buildRestClient(
            httpClient: params.httpClient ?? DefaultHttpClient.shared,
            reachabilityChecker: params.reachabilityChecker ?? ReachabilityWrapper())

        let splitApiFacade = try components.buildSplitApiFacade(testHttpClient: params.httpClient)

        let synchronizer = try components.buildSynchronizer()
        let syncManager = try components.buildSyncManager(notificationHelper: params.notificationHelper)

        setupBgSync(config: params.config, apiKey: params.apiKey, userKey: params.key.matchingKey)
        let mySegmentsSyncWorkerFactory = try components.buildMySegmentsSyncWorkerFactory()
        clientManager = DefaultClientManager(config: params.config,
                                             key: params.key,
                                             splitManager: manager,
                                             apiFacade: splitApiFacade,
                                             byKeyFacade: components.getByKeyFacade(),
                                             storageContainer: storageContainer,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsManagerCoordinator: eventsManager,
                                             mySegmentsSyncWorkerFactory: mySegmentsSyncWorkerFactory,
                                             telemetryStopwatch: params.initStopwatch)

    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
    }
}
