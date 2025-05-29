//
//  UserConsentManager.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol UserConsentManager: AnyObject {
    func set(_ status: UserConsent)
    func getStatus() -> UserConsent
}

class DefaultUserConsentManager: UserConsentManager {
    private let splitConfig: SplitClientConfig
    private let impressionsStorage: ImpressionsStorage
    private let eventsStorage: EventsStorage
    private let syncManager: SyncManager
    private let eventsTracker: EventsTracker
    private let impressionsTracker: ImpressionsTracker
    private var currentStatus: UserConsent
    private let queue = DispatchQueue(label: "split-user-consent", target: .global())

    init(
        splitConfig: SplitClientConfig,
        storageContainer: SplitStorageContainer,
        syncManager: SyncManager,
        eventsTracker: EventsTracker,
        impressionsTracker: ImpressionsTracker) { // Testing purposes
        self.splitConfig = splitConfig
        self.currentStatus = splitConfig.userConsent
        self.impressionsStorage = storageContainer.impressionsStorage
        self.eventsStorage = storageContainer.eventsStorage
        self.syncManager = syncManager
        self.eventsTracker = eventsTracker
        self.impressionsTracker = impressionsTracker
        enableTracking(for: currentStatus)
        enablePersistence(for: currentStatus)
    }

    func set(_ status: UserConsent) {
        queue.sync { [weak self] in
            guard let self = self else { return }
            self.setStatus(status)
        }
    }

    func getStatus() -> UserConsent {
        queue.sync {
            currentStatus
        }
    }

    private func setStatus(_ status: UserConsent) {
        if currentStatus == status {
            return
        }

        enableTracking(for: status)
        enablePersistence(for: status)
        syncManager.setupUserConsent(for: status)
        splitConfig.userConsent = status
        currentStatus = status
        Logger.d("User consent set to \(status.rawValue)")
    }

    private func enableTracking(for status: UserConsent) {
        let enable = (status != .declined)
        eventsTracker.isTrackingEnabled = enable
        impressionsTracker.enableTracking(enable)
        Logger.v("Tracking has been set to \(enable)")
    }

    private func enablePersistence(for status: UserConsent) {
        let enable = (status == .granted)
        impressionsStorage.enablePersistence(enable)
        eventsStorage.enablePersistence(enable)
        impressionsTracker.enablePersistence(enable)
        Logger.v("Persistence has been set to \(enable)")
    }
}
