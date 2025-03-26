//
//  PersistentRuleBasedSegmentsStorageStub.swift
//  SplitTests
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentRuleBasedSegmentsStorageStub: PersistentRuleBasedSegmentsStorage {

    var updateCalled = false
    var clearCalled = false

    var lastAddedSegments: Set<RuleBasedSegment>?
    var lastRemovedSegments: Set<RuleBasedSegment>?
    var lastChangeNumber: Int64?

    private let delegate: PersistentRuleBasedSegmentsStorage?

    init(delegate: PersistentRuleBasedSegmentsStorage?) {
        self.delegate = delegate
    }

    convenience init() {
        self.init(delegate: nil)
    }

    convenience init(database: SplitDatabase, generalInfoStorage: GeneralInfoStorage) {
        self.init(delegate: DefaultPersistentRuleBasedSegmentsStorage(
            database: database,
            generalInfoStorage: generalInfoStorage
        ))
    }

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) {
        updateCalled = true
        lastAddedSegments = toAdd
        lastRemovedSegments = toRemove
        lastChangeNumber = changeNumber
        
        delegate?.update(toAdd: toAdd, toRemove: toRemove, changeNumber: changeNumber)
    }

    func getSnapshot() -> RuleBasedSegmentsSnapshot {
        return delegate?.getSnapshot() ?? RuleBasedSegmentsSnapshot(changeNumber: -1, segments: [])
    }

    func clear() {
        clearCalled = true

        delegate?.clear()
    }
}
