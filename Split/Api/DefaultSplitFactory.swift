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
    private var userConsentManager: UserConsentManager?

    // Not using default implementation in protocol
    // extension due to Objc interoperability
    @objc public static var sdkVersion: String {
        return Version.semantic
    }

    @objc public var userConsent: UserConsent {
        userConsentManager?.getStatus() ?? .granted
    }

    private var defaultManager: SplitManager?

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

        HttpSessionConfig.default.httpsAuthenticator = params.config.httpsAuthenticator
        if let pinningConfig = params.config.certificatePinningConfig {
            let notificationHelper = params.notificationHelper ?? DefaultNotificationHelper.instance
            HttpSessionConfig.default.pinChecker = DefaultTlsPinChecker(pins: pinningConfig.pins)
            HttpSessionConfig.default.notificationHelper = notificationHelper
            if let handler = pinningConfig.failureHandler {
                notificationHelper.addObserver(for: .pinnedCredentialValidationFail) { host in
                    handler(host as? String ?? "Unknown")
                }
            }
            savePins(pinningConfig.pins, apiKey: params.apiKey)
        }

        let components = SplitComponentFactory(splitClientConfig: params.config,
                                               apiKey: params.apiKey,
                                               userKey: params.key.matchingKey)

        // Creating Events Manager first speeds up init process
        let eventsManager = components.getSplitEventsManagerCoordinator()

        let databaseName = SplitDatabaseHelper.databaseName(
            prefix: params.config.prefix,
            apiKey: params.apiKey) ?? params.config.defaultDataFolder

        let storageContainer = try components.buildStorageContainer(databaseName: databaseName,
                                                                    telemetryStorage: params.telemetryStorage,
                                                                    testDatabase: params.testDatabase)

        let rolloutCacheConfig = params.config.rolloutCacheConfiguration ?? RolloutCacheConfiguration.builder().build()
        let rolloutCacheManager = DefaultRolloutCacheManager(generalInfoStorage: storageContainer.generalInfoStorage,
                                                             rolloutCacheConfiguration: rolloutCacheConfig,
                                                             storages: storageContainer.splitsStorage,
                                                                    storageContainer.mySegmentsStorage,
                                                                    storageContainer.myLargeSegmentsStorage,
                                                                    storageContainer.ruleBasedSegmentsStorage)

        defaultManager = try components.getSplitManager()
        _ = try components.buildRestClient(
            httpClient: params.httpClient ?? DefaultHttpClient.shared,
            reachabilityChecker: params.reachabilityChecker ?? ReachabilityWrapper())

        let splitApiFacade = try components.buildSplitApiFacade(testHttpClient: params.httpClient)

        let synchronizer = try components.buildSynchronizer(notificationHelper: params.notificationHelper)
        let syncManager = try components.buildSyncManager(notificationHelper: params.notificationHelper)
        let byKeyFacade = components.getByKeyFacade()
        let mySegmentsSyncWorkerFactory = try components.buildMySegmentsSyncWorkerFactory()

        let eventsTracker = try components.buildEventsTracker()

        userConsentManager = try components.buildUserConsentManager()

        setupBgSync(config: params.config, apiKey: params.apiKey,
                    userKey: params.key.matchingKey,
                    storageContainer: storageContainer)

        // TODO: Avoid somehow this big constructor
        clientManager = DefaultClientManager(config: params.config,
                                             key: params.key,
                                             splitManager: manager,
                                             apiFacade: splitApiFacade,
                                             byKeyFacade: byKeyFacade,
                                             storageContainer: storageContainer,
                                             rolloutCacheManager: rolloutCacheManager,
                                             syncManager: syncManager,
                                             synchronizer: synchronizer,
                                             eventsTracker: eventsTracker,
                                             eventsManagerCoordinator: eventsManager,
                                             mySegmentsSyncWorkerFactory: mySegmentsSyncWorkerFactory,
                                             telemetryStopwatch: params.initStopwatch,
                                             propertyValidator: components.getPropertyValidator(),
                                             factory: self)

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

    public func setUserConsent(enabled: Bool) {
        let newMode = (enabled ? UserConsent.granted : UserConsent.declined)
        guard let userConsentManager = self.userConsentManager else {
            Logger.e("User consent manager not initialized. Unable to set mode \(newMode.rawValue)")
            return
        }
        userConsentManager.set(newMode)
    }

    private func setupBgSync(config: SplitClientConfig,
                             apiKey: String,
                             userKey: String,
                             storageContainer: SplitStorageContainer) {
#if os(iOS)
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: config.prefix, sdkKey: apiKey)
        if config.synchronizeInBackground {
            SplitBgSynchronizer.shared.register(dbKey: dbKey, prefix: config.prefix, userKey: userKey)
            storageContainer.splitsStorage.update(bySetsFilter: config.bySetsFilter())
        } else {
            SplitBgSynchronizer.shared.unregister(dbKey: dbKey, userKey: userKey)
        }
#endif
    }

    func savePins(_ pins: [CredentialPin], apiKey: String) {
        GlobalSecureStorage.shared.set(item: pins, for: .pinsConfig(apiKey))
    }
}
