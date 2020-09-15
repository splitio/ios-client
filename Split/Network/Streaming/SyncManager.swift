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
    private var isPollingEnabled = false

    init(splitConfig: SplitClientConfig, pushNotificationManager: PushNotificationManager,
         synchronizer: Synchronizer, broadcasterChannel: PushManagerEventBroadcaster) {
        self.splitConfig = splitConfig
        self.pushNotificationManager = pushNotificationManager
        self.synchronizer = synchronizer
        self.broadcasterChannel = broadcasterChannel
    }

    func start() {
        synchronizer.loadAndSynchronizeSplits()
        synchronizer.loadMySegmentsFromCache()
        synchronizer.synchronizeMySegments()
        isPollingEnabled = !splitConfig.streamingEnabled
        if splitConfig.streamingEnabled {
            broadcasterChannel.register() { event in
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
        synchronizer.stopPeriodicFetching()
        synchronizer.stopPeriodicRecording()
    }

    private func handle(pushEvent: PushStatusEvent) {
        switch pushEvent {
        case .pushSubsystemUp:
            Logger.d("Push Subsystem Up event message received.")
            synchronizer.synchronizeSplits()
            synchronizer.synchronizeMySegments()
            synchronizer.stopPeriodicFetching()
            isPollingEnabled = false
            Logger.i("Polling disabled")

        case .pushSubsystemDown:
            Logger.d("Push Subsystem Down event message received.")
            if !isPollingEnabled {
                isPollingEnabled = true
                synchronizer.startPeriodicFetching()
                Logger.i("Polling enabled")
            }

        case .pushRetryableError:
            synchronizer.startPeriodicFetching()
            pushNotificationManager.start()

        case .pushNonRetryableError, .pushDisabled:
            synchronizer.startPeriodicFetching()
            pushNotificationManager.stop()
        }
    }
}
