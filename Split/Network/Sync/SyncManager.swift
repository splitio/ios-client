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
    func setupUserConsent(for status: UserConsent)
    func pause()
    func resume()
    func stop()
}

class DefaultSyncManager: SyncManager {
    private let splitConfig: SplitClientConfig
    private let synchronizer: Synchronizer
    private let broadcasterChannel: SyncEventBroadcaster
    private let pushNotificationManager: PushNotificationManager?
    private let reconnectStreamingTimer: BackoffCounterTimer?
    private var isPollingEnabled: Atomic<Bool> = Atomic(false)
    private var isPaused: Atomic<Bool> = Atomic(false)
    private var syncGuardian: SyncGuardian

    init(
        splitConfig: SplitClientConfig,
        pushNotificationManager: PushNotificationManager?,
        reconnectStreamingTimer: BackoffCounterTimer?,
        notificationHelper: NotificationHelper,
        synchronizer: Synchronizer,
        syncGuardian: SyncGuardian,
        broadcasterChannel: SyncEventBroadcaster) {
        self.splitConfig = splitConfig
        self.pushNotificationManager = pushNotificationManager
        self.synchronizer = synchronizer
        self.broadcasterChannel = broadcasterChannel
        self.reconnectStreamingTimer = reconnectStreamingTimer
        self.syncGuardian = syncGuardian

        notificationHelper.addObserver(for: AppNotification.didBecomeActive) { [weak self] _ in
            if let self = self {
                self.resume()
            }
        }

        notificationHelper.addObserver(for: AppNotification.didEnterBackground) { [weak self] _ in
            if let self = self {
                self.pause()
            }
        }

        notificationHelper.addObserver(for: AppNotification.pinnedCredentialValidationFail) { [weak self] host in
            if let self = self, let host = host as? String {
                self.handleBannedHost(host)
            }
        }
    }

    func start() {
        broadcasterChannel.register { [weak self] event in
            guard let self = self else { return }
            self.handle(pushEvent: event)
        }
        loadData()
        // When split loaded, an events is pushed to
        // the broadcaster channel to start remote sync
    }

    private func loadData() {
        synchronizer.loadSplitsFromCache()
        synchronizer.loadMySegmentsFromCache()
        synchronizer.loadAttributesFromCache()
    }

    private func startSync() {
        synchronizer.synchronizeSplits()
        synchronizer.synchronizeMySegments()
        setupSyncMode()
        if splitConfig.userConsent == .granted {
            Logger.v("User consent grated. Recording started")
            synchronizer.startRecordingUserData()
        }
        synchronizer.startRecordingTelemetry()
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
            if syncGuardian.mustSync() {
                Logger.d("Triggering sync after being in background.")
                synchronizer.syncAll()
            }
        #endif
    }

    func stop() {
        reconnectStreamingTimer?.cancel()
        pushNotificationManager?.stop()
        synchronizer.destroy()
    }

    private func handle(pushEvent: SyncStatusEvent) {
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
            switchToPolling()

        case .pushRetryableError:
            Logger.d("Push recoverable event message received.")
            enablePolling()
            scheduleStreamingReconnection()

        case .pushNonRetryableError:
            Logger.d("Push non recoverable event message received.")
            switchToPolling()

        case .pushReset:
            Logger.d("Push Subsystem reset received.")
            pushNotificationManager?.disconnect()
            if !isPaused.value {
                scheduleStreamingReconnection()
            }

        case let .pushDelayReceived(delaySeconds):
            Logger.d("Push delay received (\(delaySeconds) secs).")
            syncGuardian.setMaxSyncPeriod(delaySeconds * 1000)

        case .syncExecuted:
            Logger.d("Sync has been executed.")
            syncGuardian.updateLastSyncTimestamp()

        case .uriTooLongOnSync:
            stopStreaming()
            synchronizer.stopPeriodicFetching()

        case .splitLoadedFromCache:
            Logger.d("Features flags has been loaded from cache.")
            startSync()
        }
    }

    func resetStreaming() {
        pushNotificationManager?.reset()
    }

    func setupUserConsent(for status: UserConsent) {
        if status == .granted {
            Logger.v("User consent status is granted now. Starting recorders")
            synchronizer.startRecordingUserData()
        } else {
            Logger.v("User consent status is \(status) now. Stopping recorders")
            synchronizer.stopRecordingUserData()
        }
    }

    private func scheduleStreamingReconnection() {
        reconnectStreamingTimer?.schedule {
            Logger.d("Scheduling streaming reconnection.")
            self.pushNotificationManager?.start()
        }
    }

    private func switchToPolling() {
        stopStreaming()
        enablePolling()
        Logger.d("Switching to polling.")
    }

    private func stopStreaming() {
        reconnectStreamingTimer?.cancel()
        pushNotificationManager?.stop()
        Logger.d("Streaming stopped.")
    }

    private func enablePolling() {
        if !isPollingEnabled.getAndSet(true) {
            synchronizer.startPeriodicFetching()
            Logger.d("Polling enabled")
        }
    }

    private func setupSyncMode() {
        if !splitConfig.syncEnabled {
            // No setup is needed
            Logger.d("Sync is disabled")
            return
        }
        isPollingEnabled.set(!splitConfig.streamingEnabled)
        if splitConfig.streamingEnabled,
           pushNotificationManager != nil,
           reconnectStreamingTimer != nil {
            pushNotificationManager?.start()
        } else {
            synchronizer.startPeriodicFetching()
        }
    }

    private func handleBannedHost(_ host: String) {
        let endpoints = splitConfig.serviceEndpoints
        Logger.e("Pinned credential validation fails for \(host). Sync disabled.")
        if check(url: endpoints.eventsEndpoint, host: host) {
            synchronizer.disableEvents()

        } else if check(url: endpoints.sdkEndpoint, host: host) {
            synchronizer.disableSdk()

        } else if check(url: endpoints.authServiceEndpoint, host: host) ||
            check(url: endpoints.streamingServiceEndpoint, host: host) {
            switchToPolling()

        } else if check(url: endpoints.telemetryServiceEndpoint, host: host) {
            synchronizer.disableTelemetry()
        }
    }

    private func check(url: URL, host: String) -> Bool {
        return url.absoluteString.contains(host)
    }
}
