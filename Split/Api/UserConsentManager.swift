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
}

class DefaultUserConsentManager: UserConsentManager {
    private let splitConfig: SplitClientConfig
    private let impressionsStorage: ImpressionsStorage
    private let eventsStorage: EventsStorage
    private let syncManager: SyncManager
    private let eventsTracker: EventsTracker
    private var currentStatus: UserConsent
    private let queue = DispatchQueue(label: "split-user-consent", target: .global())

    init(splitConfig: SplitClientConfig,
         storageContainer: SplitStorageContainer,
         syncManager: SyncManager,
         eventsTracker: EventsTracker,
         status: UserConsent = .granted) {  // Testing purposes

        self.splitConfig = splitConfig
        self.currentStatus = splitConfig.$userConsent
        self.impressionsStorage = storageContainer.impressionsStorage
        self.eventsStorage = storageContainer.eventsStorage
        self.syncManager = syncManager
        self.eventsTracker = eventsTracker
        self.currentStatus = status
    }

    func set(_ status: UserConsent) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.setStatus(status)
        }
    }

    // Just to make code clearer.
    private func setStatus(_ status: UserConsent) {
        if currentStatus == status {
            return
        }

        let  enablePersistence = (status == .granted)
        splitConfig.$userConsent = status
        eventsTracker.isTrackingEnabled = (status != .declined)
        impressionsStorage.enablePersistence(enablePersistence)
        eventsStorage.enablePersistence(enablePersistence)
        syncManager.setupUserConsent(for: status)
    }
}
