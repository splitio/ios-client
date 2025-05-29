//
//  ImpressionsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 25-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ImpressionsStorage {
    func enablePersistence(_ enable: Bool)
    func push(_ impression: KeyImpression)
    func clearInMemory()
}

// TODO: Rename persistent and this one
class MainImpressionsStorage: ImpressionsStorage {
    private let persistentStorage: PersistentImpressionsStorage
    private let impressions = SynchronizedList<KeyImpression>()
    private let isPersistenceEnabled: Atomic<Bool>

    init(
        persistentStorage: PersistentImpressionsStorage,
        persistenceEnabled: Bool = true) {
        self.persistentStorage = persistentStorage
        self.isPersistenceEnabled = Atomic(persistenceEnabled)
    }

    func enablePersistence(_ enable: Bool) {
        // Here we should save all impressions
        isPersistenceEnabled.set(enable)
        if enable {
            Logger.v("Persisting in memory impressions")
            persistentStorage.push(impressions: impressions.takeAll())
        }
        Logger.d("Persistence for impressions has been \(enable ? "enabled" : "disabled")")
    }

    func push(_ impression: KeyImpression) {
        if isPersistenceEnabled.value {
            Logger.v("Pushing impressions to persistent storage")
            persistentStorage.push(impression: impression)
            return
        }
        Logger.v("Pushing impressions to in memory storage")
        impressions.append(impression)
    }

    func clearInMemory() {
        impressions.removeAll()
    }
}
