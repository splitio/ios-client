//
//  SyncManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 08/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SyncManager {
    func start()
    func pause()
    func resume()
    func stop()
}

class DefaultSyncManager: SyncManager {

    private let splitConfig: SplitClientConfig
    private let synchronizer: Synchronizer
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let pushNotificationManager: PushNotificationManager
    private var isPollingEnabled: Atomic<Bool> = Atomic(false)

    init(splitConfig: SplitClientConfig, pushNotificationManager: PushNotificationManager,
         synchronizer: Synchronizer, broadcasterChannel: PushManagerEventBroadcaster) {
        self.splitConfig = splitConfig
        self.pushNotificationManager = pushNotificationManager
        self.synchronizer = synchronizer
        self.broadcasterChannel = broadcasterChannel
    }

    func start() {

        synchronizer.syncAll()
        isPollingEnabled.set(!splitConfig.streamingEnabled)
        if splitConfig.streamingEnabled {
            broadcasterChannel.register { event in
                self.handle(pushEvent: event)
            }
            pushNotificationManager.start()
        } else {
            synchronizer.startPeriodicFetching()
        }
        synchronizer.startPeriodicRecording()
    }

    func pause() {
        // TODO: Implement fg/bg logic
    }

    func resume() {
        // TODO: implement fg/bg logic
    }

    func stop() {
        pushNotificationManager.stop()
        synchronizer.destroy()
    }

    private func handle(pushEvent: PushStatusEvent) {
        switch pushEvent {
        case .pushSubsystemUp:
            Logger.d("Push Subsystem Up event message received.")
            synchronizer.syncAll()
            synchronizer.stopPeriodicFetching()
            isPollingEnabled.set(false)
            Logger.i("Polling disabled for api key")

        case .pushSubsystemDown:
            Logger.d("Push Subsystem Down event message received.")
            enablePolling()

        case .pushRetryableError:
            enablePolling()
            pushNotificationManager.start()

        case .pushNonRetryableError, .pushDisabled:
            enablePolling()
            pushNotificationManager.stop()
        }
    }

    private func enablePolling() {
        if !isPollingEnabled.getAndSet(true) {
            synchronizer.startPeriodicFetching()
            Logger.i("Polling enabled")
        }
    }
}
