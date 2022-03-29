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
    let oneKeyMySegmentsStorage: ByKeyMySegmentsStorage
    let impressionsStorage: PersistentImpressionsStorage
    let impressionsCountStorage: PersistentImpressionsCountStorage
    let eventsStorage: PersistentEventsStorage
    let oneKeyAttributesStorage: OneKeyAttributesStorage
    let telemetryStorage: TelemetryStorage?
    let mySegmentsStorage: MySegmentsStorage
    let attributesStorage: AttributesStorage
}

protocol ImpressionLogger {
    func pushImpression(impression: KeyImpression)
}
