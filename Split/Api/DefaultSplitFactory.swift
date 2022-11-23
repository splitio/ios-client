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

    private static let kInitErrorMessage = "Something happened on Split init and the client couldn't be created"

    private var clientManager: SplitClientManager?

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    private var defaultManager: SplitManager?
    private let filterBuilder = FilterBuilder()

    public var client: SplitClient {
        if let client = clientManager?.defaultClient {
            return client
        }
        Logger.e(Self.kInitErrorMessage)
        return FailedClient()
    }

    public var manager: SplitManager {
        if let manager = defaultManager {
        return manager
        }
        Logger.e(Self.kInitErrorMessage)
        return FailedManager()
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
        let eventsManager = components.getSplitEventsManagerCoordinator()

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

        let synchronizer = try components.buildSynchronizer(notificationHelper: params.notificationHelper)
        let syncManager = try components.buildSyncManager(notificationHelper: params.notificationHelper)
        let byKeyFacade = components.getByKeyFacade()
        let mySegmentsSyncWorkerFactory = try components.buildMySegmentsSyncWorkerFactory()

        setupBgSync(config: params.config, apiKey: params.apiKey, userKey: params.key.matchingKey)

        clientManager = DefaultClientManager(config: params.config,
                                             key: params.key,
                                             splitManager: manager,
                                             apiFacade: splitApiFacade,
                                             byKeyFacade: byKeyFacade,
                                             storageContainer: storageContainer,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsManagerCoordinator: eventsManager,
                                             mySegmentsSyncWorkerFactory: mySegmentsSyncWorkerFactory,
                                             telemetryStopwatch: params.initStopwatch)

        components.destroy()

    }

    public func client(key: Key) -> SplitClient {
        if let client = clientManager?.get(forKey: key) {
            return client
        }
        Logger.e(Self.kInitErrorMessage)
        return FailedClient()
    }

    public func client(matchingKey: String) -> SplitClient {
        return client(key: Key(matchingKey: matchingKey))
    }

    public func client(matchingKey: String, bucketingKey: String?) -> SplitClient {
        return client(key: Key(matchingKey: matchingKey, bucketingKey: bucketingKey))
    }

    private func setupBgSync(config: SplitClientConfig, apiKey: String, userKey: String) {

#if os(iOS)
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(apiKey: apiKey, userKey: userKey)
        } else {
            SplitBgSynchronizer.shared.unregister(apiKey: apiKey, userKey: userKey)
        }
#endif
    }
}
