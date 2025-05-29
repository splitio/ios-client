//
//  LocalhostSplitFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// SplitFactory implementation for Localhost mode
///
/// This mode is intended to use during development.
/// Check LocalhostSplitClient class for more information
///  - seealso:
/// [Split iOS SDK](https://docs.split.io/docs/ios-sdk-overview#section-localhost)
///
public class LocalhostSplitFactory: NSObject, SplitFactory {
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    @objc public var userConsent: UserConsent {
        return .granted
    }

    private var localhostManager: SplitManager
    private let config: SplitClientConfig
    private let bundle: Bundle
    private let synchronizer: FeatureFlagsSynchronizer
    private let externalDataSource: LocalhostInputDataProducer?
    private var clientManager: SplitClientManager?

    public var client: SplitClient {
        return clientManager?.defaultClient ?? FailedClient()
    }

    public var manager: SplitManager {
        return localhostManager
    }

    public var version: String {
        return Version.sdk
    }

    init(key: Key, config: SplitClientConfig, bundle: Bundle) {
        Logger.d("Initializing localhost mode")
        self.config = config
        self.bundle = bundle
        let dataSource = Self.splitsDataSource(config: config, bundle: bundle)
        self.externalDataSource = dataSource as? LocalhostInputDataProducer
        let eventsManager = MainSplitEventsManager()
        let splitsStorage = LocalhostSplitsStorage()
        self.localhostManager = DefaultSplitManager(splitsStorage: splitsStorage)

        self.synchronizer = LocalhostSynchronizer(
            featureFlagsStorage: splitsStorage,
            featureFlagsDataSource: dataSource,
            eventsManager: eventsManager)
        super.init()
        self.clientManager = LocalhostClientManager(
            config: config,
            key: key,
            splitManager: localhostManager,
            splitsStorage: splitsStorage,
            synchronizer: synchronizer,
            eventsManagerCoordinator: eventsManager,
            factory: self)

        synchronizer.synchronize()
    }

    public func client(key: Key) -> SplitClient {
        return client(forKey: key)
    }

    public func client(matchingKey: String) -> SplitClient {
        return client(forKey: Key(matchingKey: matchingKey))
    }

    public func client(matchingKey: String, bucketingKey: String?) -> SplitClient {
        return client(forKey: Key(matchingKey: matchingKey, bucketingKey: bucketingKey))
    }

    private func client(
        forKey key: Key,
        eventsManager: SplitEventsManager? = nil,
        splitsStorage: SplitsStorage? = nil) -> SplitClient {
        clientManager?.get(forKey: key) ?? FailedClient()
    }

    public func setUserConsent(enabled: Bool) {}

    private static func splitsDataSource(config: SplitClientConfig, bundle: Bundle) -> LocalhostDataSource {
        let dataFolderName = SplitDatabaseHelper.sanitizeForFolderName(config.localhostDataFolder)
        let fileStorage = DefaultFileStorage(dataFolderName: dataFolderName)
        var loaderConfig = FeatureFlagsFileLoaderConfig()
        loaderConfig.refreshInterval = config.offlineRefreshRate

        do {
            return try FeatureFlagsFileLoader(
                fileStorage: fileStorage,
                config: loaderConfig,
                dataFolderName: config.localhostDataFolder,
                splitsFileName: config.splitFile,
                bundle: bundle)
        } catch {
            Logger.i("Split file not found. Using inMemory datasource for localhost mode")
        }

        return LocalhostApiDataSource()
    }
}

extension LocalhostSplitFactory: SplitLocalhostDataSource {
    public func updateLocalhost(yaml: String) -> Bool {
        return (externalDataSource?.update(yaml: yaml)) != nil
    }

    public func updateLocalhost(splits: String) -> Bool {
        return (externalDataSource?.update(splits: splits)) != nil
    }
}
