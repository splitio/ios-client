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
    private var notificationHelper: NotificationHelper = DefaultNotificationHelper.instance

    func setUserKey(_ userKey: String) -> SyncManagerBuilder {
        self.userKey = userKey
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

    func build() -> SyncManager {

        guard let userKey = self.userKey,
            let config = self.splitConfig,
            let apiFacade = self.splitApiFacade,
            let endpointFactory = self.endpointFactory,
            let synchronizer = self.synchronizer,
            let storageContainer = self.storageContainer
            else {
                fatalError("Some parameter is null when creating Sync Manager")
        }

        let sseHttpConfig = HttpSessionConfig()
        sseHttpConfig.connectionTimeOut = config.sseHttpClientConnectionTimeOut
        let sseHttpClient = apiFacade.streamingHttpClient ?? DefaultHttpClient(configuration: sseHttpConfig)
        let broadcasterChannel = DefaultPushManagerEventBroadcaster()
        let notificationManagerKeeper = DefaultNotificationManagerKeeper(broadcasterChannel: broadcasterChannel)

        let notificationProcessor =  DefaultSseNotificationProcessor(
            notificationParser: DefaultSseNotificationParser(),
            splitsUpdateWorker: SplitsUpdateWorker(synchronizer: synchronizer),
            splitKillWorker: SplitKillWorker(synchronizer: synchronizer,
                                             splitsStorage: storageContainer.splitsStorage),
            mySegmentsUpdateWorker: MySegmentsUpdateWorker(synchronizer: synchronizer,
                                                           mySegmentsStorage: storageContainer.mySegmentsStorage),
            mySegmentsUpdateV2Worker: MySegmentsUpdateV2Worker(userKey: userKey, synchronizer: synchronizer,
                                                               mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                               payloadDecoder: DefaultMySegmentsV2PayloadDecoder()))

        let sseHandler = DefaultSseHandler(notificationProcessor: notificationProcessor,
                                           notificationParser: DefaultSseNotificationParser(),
                                           notificationManagerKeeper: notificationManagerKeeper,
                                           broadcasterChannel: broadcasterChannel)

        let sseAuthenticator = apiFacade.sseAuthenticator
        let sseClient = DefaultSseClient(endpoint: endpointFactory.streamingEndpoint,
                                         httpClient: sseHttpClient, sseHandler: sseHandler)

        let pushManager = DefaultPushNotificationManager(
            userKey: userKey, sseAuthenticator: sseAuthenticator, sseClient: sseClient,
            broadcasterChannel: broadcasterChannel,
            timersManager: DefaultTimersManager())

        let sseBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: config.pushRetryBackoffBase)
        let sseBackoffTimer = DefaultBackoffCounterTimer(reconnectBackoffCounter: sseBackoffCounter)

        return DefaultSyncManager(splitConfig: config, pushNotificationManager: pushManager,
                                  reconnectStreamingTimer: sseBackoffTimer,
                                  notificationHelper: notificationHelper,
                                  synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
    }
}
