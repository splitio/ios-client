//
//  PersistentRuleBasedSegmentsStorage.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation

protocol PersistentRuleBasedSegmentsStorage {
    func getSnapshot() -> RuleBasedSegmentsSnapshot
    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64)
    func clear()
    func getChangeNumber() -> Int64
    
    func getSegmentsInUse() -> Int64?
    func setSegmentsInUse(_ segmentsInUse: Int64)
}

class DefaultPersistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorage {

    private let ruleBasedSegmentDao: RuleBasedSegmentDao
    private let generalInfoStorage: GeneralInfoStorage

    init(database: SplitDatabase, generalInfoStorage: GeneralInfoStorage) {
        self.ruleBasedSegmentDao = database.ruleBasedSegmentDao
        self.generalInfoStorage = generalInfoStorage
    }

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) {
        if !toAdd.isEmpty {
            ruleBasedSegmentDao.insertOrUpdate(segments: Array(toAdd))
        }

        if !toRemove.isEmpty {
            let segmentNames = toRemove.compactMap { return $0.name }
            if !segmentNames.isEmpty {
                ruleBasedSegmentDao.delete(segmentNames)
            }
        }

        generalInfoStorage.setRuleBasedSegmentsChangeNumber(changeNumber: changeNumber)
    }

    func getSnapshot() -> RuleBasedSegmentsSnapshot {
        return RuleBasedSegmentsSnapshot(
            changeNumber: generalInfoStorage.getRuleBasedSegmentsChangeNumber(),
            segments: ruleBasedSegmentDao.getAll()
        )
    }

    func clear() {
        generalInfoStorage.setRuleBasedSegmentsChangeNumber(changeNumber: -1)
        ruleBasedSegmentDao.deleteAll()
    }

    func getChangeNumber() -> Int64 {
        return generalInfoStorage.getRuleBasedSegmentsChangeNumber()
    }
    
    func getSegmentsInUse() -> Int64? {
        generalInfoStorage.getSegmentsInUse()
    }
    
    func setSegmentsInUse(_ segmentsInUse: Int64) {
        generalInfoStorage.setSegmentsInUse(segmentsInUse)
    }
}
