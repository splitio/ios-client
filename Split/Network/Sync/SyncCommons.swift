//
//  SyncCommons.swift
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
    let mySegmentsStorage: OneKeyMySegmentsStorage
    let impressionsStorage: PersistentImpressionsStorage
    let impressionsCountStorage: PersistentImpressionsCountStorage
    let eventsStorage: PersistentEventsStorage
    let attributesStorage: OneKeyAttributesStorage
    let telemetryStorage: TelemetryStorage?
}

protocol ImpressionLogger {
    func pushImpression(impression: KeyImpression)
}
