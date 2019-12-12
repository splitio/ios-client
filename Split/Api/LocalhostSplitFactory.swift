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

    private let localhostClient: SplitClient
    private let localhostManager: SplitManager
    private let eventsManager: SplitEventsManager

    public var client: SplitClient {
        return localhostClient
    }

    public var manager: SplitManager {
        return localhostManager
    }

    public var version: String {
        return Version.sdk
    }

    init(key: Key, config: SplitClientConfig, bundle: Bundle) {

        eventsManager = DefaultSplitEventsManager(config: config)
        eventsManager.start()

        let fileStorage = FileStorage(dataFolderName: DataFolderFactory()
            .sanitizeForFolderName(config.localhostDataFolder))

        let splitCache: SplitCacheProtocol = InMemorySplitCache()
        let splitFetcher: RefreshableSplitFetcher = LocalhostSplitFetcher(fileStorage: fileStorage,
                                                               splitCache: splitCache,
                                                               eventsManager: eventsManager,
                                                               splitsFileName: config.splitFile,
                                                               bundle: bundle)
        localhostClient = LocalhostSplitClient(key: key, splitFetcher: splitFetcher, eventsManager: eventsManager)
        eventsManager.getExecutorResources().setClient(client: localhostClient)
        localhostManager = DefaultSplitManager(splitCache: splitCache)
    }
}
