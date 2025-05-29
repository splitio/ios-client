//
//  SyncManagerBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class SyncManagerBuilder {
    private var userKey: String?
    private var splitConfig: SplitClientConfig?
    private var splitApiFacade: SplitApiFacade?
    private var storageContainer: SplitStorageContainer?
    private var endpointFactory: EndpointFactory?
    private var synchronizer: Synchronizer?
    private var byKeyFacade: ByKeyFacade?
    private var broadcasterChannel: SyncEventBroadcaster?
    private var notificationHelper: NotificationHelper = DefaultNotificationHelper.instance

    func setUserKey(_ userKey: String) -> SyncManagerBuilder {
        self.userKey = userKey
        return self
    }

    func setByKeyFacade(_ byKeyFacade: ByKeyFacade) -> SyncManagerBuilder {
        self.byKeyFacade = byKeyFacade
        return self
    }

    func setSplitConfig(_ splitConfig: SplitClientConfig) -> SyncManagerBuilder {
        self.splitConfig = splitConfig
        return self
    }

    func setSplitApiFacade(_ apiFacade: SplitApiFacade) -> SyncManagerBuilder {
        splitApiFacade = apiFacade
        return self
    }

    func setStorageContainer(_ storageContainer: SplitStorageContainer) -> SyncManagerBuilder {
        self.storageContainer = storageContainer
        return self
    }

    func setEndpointFactory(_ endpointFactory: EndpointFactory) -> SyncManagerBuilder {
        self.endpointFactory = endpointFactory
        return self
    }

    func setSynchronizer(_ synchronizer: Synchronizer) -> SyncManagerBuilder {
        self.synchronizer = synchronizer
        return self
    }

    func setSyncBroadcaster(_ broadcasterChannel: SyncEventBroadcaster) -> SyncManagerBuilder {
        self.broadcasterChannel = broadcasterChannel
        return self
    }

    func setNotificationHelper(_ notificationHelper: NotificationHelper) -> SyncManagerBuilder {
        self.notificationHelper = notificationHelper
        return self
    }

    func build() throws -> SyncManager {
        guard let config = splitConfig,
              let synchronizer = synchronizer,
              let broadcasterChannel = broadcasterChannel
        else {
            throw ComponentError.buildFailed(name: "SyncManager")
        }

        let syncGuardian = DefaultSyncGuardian(
            maxSyncPeriod: ServiceConstants.maxSyncPeriodInMillis,
            splitConfig: config)
        var pushNotificationManager: PushNotificationManager?
        var sseBackoffTimer: BackoffCounterTimer?
        if config.syncEnabled, config.streamingEnabled {
            pushNotificationManager = try buildPushManager(broadcasterChannel: broadcasterChannel)

            sseBackoffTimer = buildSseBackoffTimer(config: config)
        }

        return DefaultSyncManager(
            splitConfig: config,
            pushNotificationManager: pushNotificationManager,
            reconnectStreamingTimer: sseBackoffTimer,
            notificationHelper: notificationHelper,
            synchronizer: synchronizer,
            syncGuardian: syncGuardian,
            broadcasterChannel: broadcasterChannel)
    }

    private func buildSseBackoffTimer(config: SplitClientConfig) -> BackoffCounterTimer {
        let sseBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: config.pushRetryBackoffBase)
        return DefaultBackoffCounterTimer(reconnectBackoffCounter: sseBackoffCounter)
    }

    private func buildSseHttpClient(
        config: SplitClientConfig,
        apiFacade: SplitApiFacade) -> HttpClient {
        let sseHttpConfig = HttpSessionConfig()
        sseHttpConfig.httpsAuthenticator = config.httpsAuthenticator
        sseHttpConfig.connectionTimeOut = config.sseHttpClientConnectionTimeOut
        sseHttpConfig.notificationHelper = notificationHelper
        if let pinningConfig = config.certificatePinningConfig {
            sseHttpConfig.pinChecker = DefaultTlsPinChecker(pins: pinningConfig.pins)
        }
        return apiFacade.streamingHttpClient ?? DefaultHttpClient(configuration: sseHttpConfig)
    }

    private func buildNotificationProcessor(
        userKey: String,
        storageContainer: SplitStorageContainer,
        synchronizer: Synchronizer) -> SseNotificationProcessor {
        let segmentsUpdateWorker = SegmentsUpdateWorker(
            synchronizer: MySegmentsSynchronizerWrapper(synchronizer: synchronizer),
            mySegmentsStorage: storageContainer.mySegmentsStorage,
            payloadDecoder: DefaultSegmentsPayloadDecoder(),
            telemetryProducer: storageContainer.telemetryStorage,
            resource: .mySegments)

        let largeSegmentsUpdateWorker = SegmentsUpdateWorker(
            synchronizer: MySegmentsSynchronizerWrapper(synchronizer: synchronizer),
            mySegmentsStorage: storageContainer.myLargeSegmentsStorage,
            payloadDecoder: DefaultSegmentsPayloadDecoder(),
            telemetryProducer: storageContainer.telemetryStorage,
            resource: .myLargeSegments)

        return DefaultSseNotificationProcessor(
            notificationParser: DefaultSseNotificationParser(),
            splitsUpdateWorker: SplitsUpdateWorker(
                synchronizer: synchronizer,
                splitsStorage: storageContainer.splitsStorage,
                ruleBasedSegmentsStorage: storageContainer.ruleBasedSegmentsStorage,
                splitChangeProcessor: DefaultSplitChangeProcessor(filterBySet: splitConfig?.bySetsFilter()),
                ruleBasedSegmentsChangeProcessor: DefaultRuleBasedSegmentChangeProcessor(),
                featureFlagsPayloadDecoder: DefaultFeatureFlagsPayloadDecoder(type: Split.self),
                ruleBasedSegmentsPayloadDecoder: DefaultRuleBasedSegmentsPayloadDecoder(type: RuleBasedSegment.self),
                telemetryProducer: storageContainer.telemetryStorage),
            splitKillWorker: SplitKillWorker(
                synchronizer: synchronizer,
                splitsStorage: storageContainer.splitsStorage),
            mySegmentsUpdateWorker: segmentsUpdateWorker,
            myLargeSegmentsUpdateWorker: largeSegmentsUpdateWorker)
    }

    private func buildPushManager(broadcasterChannel: SyncEventBroadcaster)
        throws -> PushNotificationManager {
        guard let userKey = userKey,
              let byKeyFacade = byKeyFacade,
              let config = splitConfig,
              let apiFacade = splitApiFacade,
              let endpointFactory = endpointFactory,
              let synchronizer = synchronizer,
              let storageContainer = storageContainer
        else {
            throw ComponentError.buildFailed(name: "SyncManager")
        }

        let sseHttpClient = buildSseHttpClient(config: config, apiFacade: apiFacade)
        let notificationManagerKeeper
            = DefaultNotificationManagerKeeper(
                broadcasterChannel: broadcasterChannel,
                telemetryProducer: storageContainer.telemetryStorage)

        let notificationProcessor = buildNotificationProcessor(
            userKey: userKey,
            storageContainer: storageContainer,
            synchronizer: synchronizer)

        let sseHandler = DefaultSseHandler(
            notificationProcessor: notificationProcessor,
            notificationParser: DefaultSseNotificationParser(),
            notificationManagerKeeper: notificationManagerKeeper,
            broadcasterChannel: broadcasterChannel,
            telemetryProducer: storageContainer.telemetryStorage)

        let sseClientFactory = DefaultSseClientFactory(
            endpoint: endpointFactory.streamingEndpoint,
            httpClient: sseHttpClient,
            sseHandler: sseHandler)

        let sseConnectionHandler = SseConnectionHandler(sseClientFactory: sseClientFactory)

        return DefaultPushNotificationManager(
            userKeyRegistry: byKeyFacade,
            sseAuthenticator: apiFacade.sseAuthenticator,
            broadcasterChannel: broadcasterChannel,
            timersManager: DefaultTimersManager(),
            telemetryProducer: storageContainer.telemetryStorage,
            sseConnectionHandler: sseConnectionHandler)
    }
}
