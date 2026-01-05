//
//  SplitsPersistenceBreakerIntegrationTest.swift
//  SplitTests
//

import Foundation
import XCTest
@testable import Split

class SplitsPersistenceBreakerIntegrationTest: XCTestCase {
    
    var splitsStorage: DefaultSplitsStorage!
    var persistentStorage: FailingPersistentSplitsStorage!
    var flagSetsCache: FlagSetsCacheMock!
    var generalInfoStorage: GeneralInfoStorageMock!
    var persistenceBreaker: DefaultPersistenceBreaker!
    
    override func setUp() {
        super.setUp()
        persistentStorage = FailingPersistentSplitsStorage()
        flagSetsCache = FlagSetsCacheMock()
        generalInfoStorage = GeneralInfoStorageMock()
        persistenceBreaker = DefaultPersistenceBreaker()
        
        splitsStorage = DefaultSplitsStorage(
            persistentSplitsStorage: persistentStorage,
            flagSetsCache: flagSetsCache,
            generalInfoStorage: generalInfoStorage,
            persistenceBreaker: persistenceBreaker
        )
    }

    func testFirstPersistenceFailureDisablesFurtherPersistence() {
        persistentStorage.shouldFail = true
        persistentStorage.failOnCallNumber = 1
        
        let change1 = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )
        
        let change2 = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split2")],
            archivedSplits: [],
            changeNumber: 200,
            updateTimestamp: 2000
        )
        
        _ = splitsStorage.update(splitChange: change1)
        
        XCTAssertEqual(1, persistentStorage.updateCallCount, "First update should attempt persistence")
        
        _ = splitsStorage.update(splitChange: change2)
        
        XCTAssertEqual(1, persistentStorage.updateCallCount,
                      "After first failure, no further persistence calls should occur")
    }

    func testInMemorySplitsStillWorkAfterPersistenceDisabled() {
        persistentStorage.shouldFail = true
        persistentStorage.failOnCallNumber = 1
        
        let change1 = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )
        
        let change2 = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split2")],
            archivedSplits: [],
            changeNumber: 200,
            updateTimestamp: 2000
        )
    
        _ = splitsStorage.update(splitChange: change1)
        _ = splitsStorage.update(splitChange: change2)
        
        XCTAssertNotNil(splitsStorage.get(name: "split1"),
                       "First split should be in memory despite persistence failure")
        XCTAssertNotNil(splitsStorage.get(name: "split2"),
                       "Second split should be in memory (persistence skipped)")

        XCTAssertEqual(200, splitsStorage.changeNumber,
                      "In-memory change number should advance even when persistence disabled")
        XCTAssertEqual(2000, splitsStorage.updateTimestamp,
                      "In-memory timestamp should advance even when persistence disabled")
    }

    private func createSplit(name: String, trafficType: String = "user") -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: trafficType)
        split.status = .active
        return split
    }
}

class FailingPersistentSplitsStorage: PersistentSplitsStorage {

    var shouldFail = false
    var failOnCallNumber: Int = 1
    var updateCallCount = 0
    var failureReported = false
    
    private var snapshot = SplitsSnapshot(changeNumber: -1, splits: [], updateTimestamp: -1)
    
    func update(splitChange: ProcessedSplitChange, onFailure: ((Error) -> Void)? = nil) {
        updateCallCount += 1
        
        if shouldFail && updateCallCount == failOnCallNumber {
            // Simulate a CoreData save() failure
            let error = NSError(domain: "TestCoreData", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Simulated CoreData save failure"])
            failureReported = true
            onFailure?(error)
            return
        }
        
        // Normal success path (not failing)
        snapshot = SplitsSnapshot(
            changeNumber: splitChange.changeNumber,
            splits: splitChange.activeSplits,
            updateTimestamp: splitChange.updateTimestamp
        )
    }
    
    func update(split: Split) {
        // No-op for this test
    }
    
    func update(bySetsFilter: SplitFilter?) {
        // No-op for this test
    }
    
    func getBySetsFilter() -> SplitFilter? {
        return nil
    }
    
    func getSplitsSnapshot() -> SplitsSnapshot {
        return snapshot
    }
    
    func getChangeNumber() -> Int64 {
        return snapshot.changeNumber
    }
    
    func getUpdateTimestamp() -> Int64 {
        return snapshot.updateTimestamp
    }
    
    func getAll() -> [Split] {
        return snapshot.splits
    }
    
    func delete(splitNames: [String]) {
        // No-op for this test
    }
    
    func clear() {
        snapshot = SplitsSnapshot(changeNumber: -1, splits: [], updateTimestamp: -1)
    }
}

