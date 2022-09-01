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

    struct LocalhostComponentsGroup {
        let client: SplitClient
        let eventsManager: SplitEventsManager
    }

    private var clients = SynchronizedDictionary<String, LocalhostComponentsGroup>()

    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    private var defaulClient: SplitClient?
    private var localhostManager: SplitManager?
    private let config: SplitClientConfig
    private let bundle: Bundle

    public var client: SplitClient {
        return defaulClient ?? FailedClient()
    }

    public var manager: SplitManager {
        return localhostManager ?? FailedManager()
    }

    public var version: String {
        return Version.sdk
    }

    init(key: Key, config: SplitClientConfig, bundle: Bundle) {
        Logger.d("Initializing localhost mode")
        self.config = config
        self.bundle = bundle
        super.init()

        let eventsManager = DefaultSplitEventsManager(config: config)
        let splitsStorage = buildSplitStorage(eventsManager: eventsManager)
        defaulClient = client(forKey: key,
                              eventsManager: eventsManager,
                              splitsStorage: splitsStorage)
        localhostManager = DefaultSplitManager(splitsStorage: splitsStorage)
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

    private func client(forKey key: Key,
                        eventsManager: SplitEventsManager? = nil,
                        splitsStorage: SplitsStorage? = nil) -> SplitClient {

        if let group = clients.value(forKey: key.matchingKey) {
            return group.client
        }

        let newEventsManager = eventsManager ?? DefaultSplitEventsManager(config: config)
        newEventsManager.start()

        let newSplitStorage = splitsStorage ?? buildSplitStorage(eventsManager: newEventsManager)

        let newClient = LocalhostSplitClient(key: key,
                                             splitsStorage: newSplitStorage,
                                             eventsManager: newEventsManager)

        let newGroup = LocalhostComponentsGroup(client: newClient, eventsManager: newEventsManager)
        newEventsManager.executorResources.client = newClient
        clients.setValue(newGroup, forKey: key.matchingKey)

        return newClient
    }

    private func buildSplitStorage(eventsManager: SplitEventsManager) -> SplitsStorage {
        let dataFolderName = SplitDatabaseHelper.sanitizeForFolderName(config.localhostDataFolder)
        let fileStorage = FileStorage(dataFolderName: dataFolderName)

        var storageConfig = YamlSplitStorageConfig()
        storageConfig.refreshInterval = config.offlineRefreshRate

        return LocalhostSplitsStorage(fileStorage: fileStorage,
                                      config: storageConfig,
                                      eventsManager: eventsManager,
                                      dataFolderName: dataFolderName,
                                      splitsFileName: config.splitFile,
                                      bundle: bundle)
    }
}
