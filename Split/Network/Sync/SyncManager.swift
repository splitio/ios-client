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
    func resetStreaming()
    func pause()
    func resume()
    func stop()
}

class DefaultSyncManager: SyncManager {

    private let splitConfig: SplitClientConfig
    private let synchronizer: Synchronizer
    private let broadcasterChannel: PushManagerEventBroadcaster
    private let pushNotificationManager: PushNotificationManager?
    private let reconnectStreamingTimer: BackoffCounterTimer?
    private var isPollingEnabled: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)

    init(splitConfig: SplitClientConfig,
         pushNotificationManager: PushNotificationManager?,
         reconnectStreamingTimer: BackoffCounterTimer?,
         notificationHelper: NotificationHelper,
         synchronizer: Synchronizer,
         broadcasterChannel: PushManagerEventBroadcaster) {
        self.splitConfig = splitConfig
        self.pushNotificationManager = pushNotificationManager
        self.synchronizer = synchronizer
        self.broadcasterChannel = broadcasterChannel
        self.reconnectStreamingTimer = reconnectStreamingTimer

        notificationHelper.addObserver(for: AppNotification.didBecomeActive) { [weak self] in
            if let self = self {
                self.resume()
            }
        }

        notificationHelper.addObserver(for: AppNotification.didEnterBackground) { [weak self] in
            if let self = self {
                self.pause()
            }
        }
    }

    func start() {
        synchronizer.loadAndSynchronizeSplits()
        synchronizer.loadMySegmentsFromCache()
        synchronizer.loadAttributesFromCache()
        synchronizer.synchronizeMySegments()
        setupSyncMode()
        synchronizer.startPeriodicRecording()
    }

    func pause() {
#if !os(macOS)
        isPaused.set(true)
        pushNotificationManager?.pause()
        synchronizer.pause()
#endif
    }

    func resume() {
#if !os(macOS)
        isPaused.set(false)
        synchronizer.resume()
        pushNotificationManager?.resume()
#endif
    }

    func stop() {
        reconnectStreamingTimer?.cancel()
        pushNotificationManager?.stop()
        synchronizer.destroy()
    }

    private func handle(pushEvent: PushStatusEvent) {
        if isPaused.value {
            return
        }

        switch pushEvent {
        case .pushSubsystemUp:
            Logger.d("Push Subsystem Up event message received.")
            reconnectStreamingTimer?.cancel()
            synchronizer.syncAll()
            synchronizer.stopPeriodicFetching()
            isPollingEnabled.set(false)
            Logger.i("Polling disabled")

        case .pushSubsystemDown:
            Logger.d("Push Subsystem Down event message received.")
            reconnectStreamingTimer?.cancel()
            enablePolling()

        case .pushSubsystemDisabled:
            Logger.d("Push Subsystem Disabled event message received.")
            stopStreaming()

        case .pushRetryableError:
            Logger.d("Push recoverable event message received.")
            enablePolling()
            scheduleStreamingReconnection()

        case .pushNonRetryableError:
            Logger.d("Push non recoverable event message received.")
            stopStreaming()

        case .pushReset:
            Logger.d("Push Subsystem reset received.")
            pushNotificationManager?.disconnect()
            if !isPaused.value {
                scheduleStreamingReconnection()
            }
        }
    }

    func resetStreaming() {
        pushNotificationManager?.reset()
    }

    private func scheduleStreamingReconnection() {
        reconnectStreamingTimer?.schedule {
            self.pushNotificationManager?.start()
        }
    }

    private func stopStreaming() {
        reconnectStreamingTimer?.cancel()
        enablePolling()
        pushNotificationManager?.stop()
    }

    private func enablePolling() {
        if !isPollingEnabled.getAndSet(true) {
            synchronizer.startPeriodicFetching()
            Logger.i("Polling enabled")
        }
    }

    private func setupSyncMode() {
        if !splitConfig.syncEnabled {
            // No setup is needed
            return
        }
        isPollingEnabled.set(!splitConfig.streamingEnabled)
        if splitConfig.streamingEnabled,
           pushNotificationManager != nil,
           reconnectStreamingTimer != nil {
            broadcasterChannel.register { event in
                self.handle(pushEvent: event)
            }
            pushNotificationManager?.start()
        } else {
            synchronizer.startPeriodicFetching()
        }
    }
}
