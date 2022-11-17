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
        self.splitApiFacade = apiFacade
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

    func setNotificationHelper(_ notificationHelper: NotificationHelper) -> SyncManagerBuilder {
        self.notificationHelper = notificationHelper
        return self
    }

    private struct Components {
        let userKey: String
        let byKeyFacade: ByKeyFacade
        let config: SplitClientConfig
        let apiFacade: SplitApiFacade
        let endpointFactory: EndpointFactory
        let synchronizer: Synchronizer
        let storageContainer: SplitStorageContainer
    }

    func build() throws -> SyncManager {

        guard let config = self.splitConfig,
              let synchronizer = self.synchronizer
        else {
            throw ComponentError.buildFailed(name: "SyncManager")
        }

        let broadcasterChannel = DefaultPushManagerEventBroadcaster()
        var pushNotificationManager: PushNotificationManager?
        var sseBackoffTimer: BackoffCounterTimer?
        if config.syncEnabled, config.streamingEnabled {
            pushNotificationManager = try buildPushManager(broadcasterChannel: broadcasterChannel)

            sseBackoffTimer = buildSseBackoffTimer(config: config)
        }

        return DefaultSyncManager(splitConfig: config,
                                  pushNotificationManager: pushNotificationManager,
                                  reconnectStreamingTimer: sseBackoffTimer,
                                  notificationHelper: notificationHelper,
                                  synchronizer: synchronizer,
                                  broadcasterChannel: broadcasterChannel)
    }

    private func buildSseBackoffTimer(config: SplitClientConfig) -> BackoffCounterTimer {
        let sseBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: config.pushRetryBackoffBase)
        return DefaultBackoffCounterTimer(reconnectBackoffCounter: sseBackoffCounter)
    }

    private func buildSseHttpClient(config: SplitClientConfig,
                                    apiFacade: SplitApiFacade) -> HttpClient {
        let sseHttpConfig = HttpSessionConfig()
        sseHttpConfig.connectionTimeOut = config.sseHttpClientConnectionTimeOut
        return apiFacade.streamingHttpClient ?? DefaultHttpClient(configuration: sseHttpConfig)
    }

    private func buildNotificationProcessor(userKey: String,
                                            storageContainer: SplitStorageContainer,
                                            synchronizer: Synchronizer) -> SseNotificationProcessor {

        let mySegmentsUpdateWorker
        = MySegmentsUpdateWorker(synchronizer: synchronizer,
                                 mySegmentsStorage: storageContainer.mySegmentsStorage,
                                 mySegmentsPayloadDecoder: DefaultMySegmentsPayloadDecoder())

        return  DefaultSseNotificationProcessor(
            notificationParser: DefaultSseNotificationParser(),
            splitsUpdateWorker: SplitsUpdateWorker(synchronizer: synchronizer),
            splitKillWorker: SplitKillWorker(synchronizer: synchronizer,
                                             splitsStorage: storageContainer.splitsStorage),
            mySegmentsUpdateWorker: mySegmentsUpdateWorker,
            mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker(
                userKey: userKey, synchronizer: synchronizer,
                mySegmentsStorage: storageContainer.mySegmentsStorage,
                payloadDecoder: DefaultMySegmentsV2PayloadDecoder()))
    }

    private func buildPushManager(broadcasterChannel: PushManagerEventBroadcaster)
    throws -> PushNotificationManager {

        guard let userKey = self.userKey,
              let byKeyFacade = self.byKeyFacade,
              let config = self.splitConfig,
              let apiFacade = self.splitApiFacade,
              let endpointFactory = self.endpointFactory,
              let synchronizer = self.synchronizer,
              let storageContainer = self.storageContainer
        else {
            throw ComponentError.buildFailed(name: "SyncManager")
        }

        let sseHttpClient = buildSseHttpClient(config: config, apiFacade: apiFacade)
        let notificationManagerKeeper
        = DefaultNotificationManagerKeeper(broadcasterChannel: broadcasterChannel,
                                           telemetryProducer: storageContainer.telemetryStorage)

        let notificationProcessor = buildNotificationProcessor(userKey: userKey,
                                                               storageContainer: storageContainer,
                                                               synchronizer: synchronizer)

        let sseHandler = DefaultSseHandler(notificationProcessor: notificationProcessor,
                                           notificationParser: DefaultSseNotificationParser(),
                                           notificationManagerKeeper: notificationManagerKeeper,
                                           broadcasterChannel: broadcasterChannel,
                                           telemetryProducer: storageContainer.telemetryStorage)

        let sseClientFactory  = DefaultSseClientFactory(endpoint: endpointFactory.streamingEndpoint,
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
