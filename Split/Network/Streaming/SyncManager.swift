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
    private let reconnectStreamingTimer: BackoffCounterTimer
    
    private var isPollingEnabled: Atomic<Bool> = Atomic(false)

    init(splitConfig: SplitClientConfig, pushNotificationManager: PushNotificationManager,
         reconnectStreamingTimer: BackoffCounterTimer,
         synchronizer: Synchronizer, broadcasterChannel: PushManagerEventBroadcaster) {
        self.splitConfig = splitConfig
        self.pushNotificationManager = pushNotificationManager
        self.synchronizer = synchronizer
        self.broadcasterChannel = broadcasterChannel
        self.reconnectStreamingTimer = reconnectStreamingTimer
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
        reconnectStreamingTimer.cancel()
        pushNotificationManager.stop()
        synchronizer.destroy()
    }

    private func handle(pushEvent: PushStatusEvent) {
        switch pushEvent {
        case .pushSubsystemUp:
            Logger.d("Push Subsystem Up event message received.")
            reconnectStreamingTimer.cancel()
            synchronizer.syncAll()
            synchronizer.stopPeriodicFetching()
            isPollingEnabled.set(false)
            Logger.i("Polling disabled")

        case .pushSubsystemDown:
            Logger.d("Push Subsystem Down event message received.")
            reconnectStreamingTimer.cancel()
            enablePolling()
            pushNotificationManager.stop()

        case .pushRetryableError:
            Logger.d("Push recoverable event message received.")
            enablePolling()
            reconnectStreamingTimer.schedule {
                self.pushNotificationManager.start()
            }

        case .pushNonRetryableError:
            Logger.d("Push non recoverable event message received.")
            reconnectStreamingTimer.cancel()
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
