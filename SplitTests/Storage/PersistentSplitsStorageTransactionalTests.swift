//
//  PersistentSplitsStorageTransactionalTests.swift
//  SplitTests
//

import Foundation
import XCTest
@testable import Split

class PersistentSplitsStorageTransactionalTests: XCTestCase {
    
    var splitsStorage: PersistentSplitsStorage!
    var splitDao: SplitDaoStub!
    var generalInfoDao: GeneralInfoDaoStub!
    var coreDataHelperStub: CoreDataHelperStub!
    
    override func setUp() {
        splitDao = SplitDaoStub()
        generalInfoDao = GeneralInfoDaoStub()
        coreDataHelperStub = CoreDataHelperStub()
        var daoProvider = CoreDataDaoProviderMock()
        daoProvider.splitDao = splitDao
        daoProvider.generalInfoDao = generalInfoDao
        splitsStorage = DefaultPersistentSplitsStorage(
            database: SplitDatabaseStub(daoProvider: daoProvider, coreDataHelper: coreDataHelperStub)
        )
    }

    func testSuccessDoesNotInvokeFailureCallback() {
        let change = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )
        
        var failureWasReported = false
        
        splitsStorage.update(splitChange: change, onFailure: { _ in
            failureWasReported = true
        })
        
        XCTAssertFalse(failureWasReported, "With working stubs, no failure should occur")
    }
    
    func testFailureCallbackIsInvokedOnSaveError() {
        coreDataHelperStub.shouldFailOnSave = true
        
        let change = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )
        
        var failureWasReported = false
        var reportedError: Error?
        
        splitsStorage.update(splitChange: change, onFailure: { error in
            failureWasReported = true
            reportedError = error
        })
        
        XCTAssertTrue(failureWasReported, "Failure callback should be invoked on save error")
        XCTAssertNotNil(reportedError, "Error should be reported")
    }

    func testRollbackIsInvokedOnSaveError() {
        coreDataHelperStub.shouldFailOnSave = true

        let change = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )

        splitsStorage.update(splitChange: change, onFailure: { _ in })

        XCTAssertTrue(coreDataHelperStub.rollbackCalled, "Rollback should be invoked when transactional save fails")
    }

    func testNilFailureCallbackIsHandled() {
        let change = ProcessedSplitChange(
            activeSplits: [createSplit(name: "split1")],
            archivedSplits: [],
            changeNumber: 100,
            updateTimestamp: 1000
        )
        
        splitsStorage.update(splitChange: change, onFailure: nil)
        
        XCTAssertEqual(1, splitDao.insertedSplits.count)
        XCTAssertEqual(100, generalInfoDao.longValue(info: .splitsChangeNumber))
    }

    func testSplitsAndGeneralInfoAreUpdatedTogether() {
        let activeSplits = [createSplit(name: "s1"), createSplit(name: "s2")]
        let archivedSplits = [createSplit(name: "s3")]
        let change = ProcessedSplitChange(
            activeSplits: activeSplits,
            archivedSplits: archivedSplits,
            changeNumber: 200,
            updateTimestamp: 2000
        )
        
        splitsStorage.update(splitChange: change, onFailure: nil)
        
        XCTAssertEqual(2, splitDao.insertedSplits.count, "Active splits should be inserted")
        XCTAssertEqual(1, splitDao.deletedSplits?.count, "Archived splits should be deleted")
        XCTAssertEqual(200, generalInfoDao.longValue(info: .splitsChangeNumber), "ChangeNumber should be updated")
        XCTAssertEqual(2000, generalInfoDao.longValue(info: .splitsUpdateTimestamp), "UpdateTimestamp should be updated")
    }

    private func createSplit(name: String, trafficType: String = "user") -> Split {
        let split = SplitTestHelper.newSplit(name: name, trafficType: trafficType)
        split.status = .active
        return split
    }
}

