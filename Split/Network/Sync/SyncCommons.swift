//
//  SplitStorageContainer.swift
//  Split
//
//  Created by Javier Avrudsky on 09-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

struct SplitStorageContainer {
    let splitDatabase: SplitDatabase
    let fileStorage: FileStorageProtocol
    let splitsStorage: SplitsStorage
    let persistentSplitsStorage: PersistentSplitsStorage
    let impressionsStorage: PersistentImpressionsStorage
    let impressionsCountStorage: PersistentImpressionsCountStorage
    let eventsStorage: PersistentEventsStorage
    let telemetryStorage: TelemetryStorage?
    let mySegmentsStorage: MySegmentsStorage
    let attributesStorage: AttributesStorage
    let uniqueKeyStorage: PersistentUniqueKeysStorage?
}

protocol ImpressionLogger {
    func pushImpression(impression: KeyImpression)
}
