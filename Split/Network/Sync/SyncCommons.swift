//
//  SplitStorageContainer.swift
//  Split
//
//  Created by Javier Avrudsky on 09-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

struct SplitStorageContainer {
    let splitDatabase: SplitDatabase
    let splitsStorage: SplitsStorage
    let persistentSplitsStorage: PersistentSplitsStorage
    let impressionsStorage: ImpressionsStorage
    let persistentImpressionsStorage: PersistentImpressionsStorage
    let impressionsCountStorage: PersistentImpressionsCountStorage
    let eventsStorage: EventsStorage
    let persistentEventsStorage: PersistentEventsStorage
    let telemetryStorage: TelemetryStorage?
    let mySegmentsStorage: MySegmentsStorage
    let myLargeSegmentsStorage: MySegmentsStorage
    let attributesStorage: AttributesStorage
    let uniqueKeyStorage: PersistentUniqueKeysStorage
    let flagSetsCache: FlagSetsCache
    let persistentHashedImpressionsStorage: PersistentHashedImpressionsStorage
    let hashedImpressionsStorage: HashedImpressionsStorage
    let generalInfoStorage: GeneralInfoStorage
    let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    let persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorage
}

protocol ImpressionLogger {
    func pushImpression(impression: DecoratedImpression)
}
