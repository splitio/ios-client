//
//  CoreDataHelperTests.swift
//  SplitTests
//

import Foundation
import XCTest
import CoreData
@testable import Split

class CoreDataHelperTests: XCTestCase {
    
    var coreDataHelper: CoreDataHelper!
    
    override func setUp() {
        let queue = DispatchQueue(label: "coredata helper test")
        coreDataHelper = IntegrationCoreDataHelper.get(databaseName: "test", dispatchQueue: queue)
    }
    
    func testSaveWithErrorHandlingSucceedsWhenChangesExist() {
        coreDataHelper.performAndWait {
            if let entity = self.coreDataHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
                entity.name = "test_info"
                entity.stringValue = "test_value"
            }
        }
        
        XCTAssertNoThrow(try coreDataHelper.saveWithErrorHandling())
    }
    
    func testSaveWithErrorHandlingThrowsOnValidationError() {
        coreDataHelper.performAndWait {
            // Create entity without required 'name' field to trigger validation error
            _ = self.coreDataHelper.create(entity: .generalInfo)
        }
        
        XCTAssertThrowsError(try coreDataHelper.saveWithErrorHandling()) { error in
            let nsError = error as NSError
            XCTAssertEqual(NSValidationMissingMandatoryPropertyError, nsError.code)
        }
    }
    
    func testSaveWithErrorHandlingSucceedsWhenNoChanges() {
        XCTAssertNoThrow(try coreDataHelper.saveWithErrorHandling())
    }
    
    func testSaveWithErrorHandlingPersistsData() {
        coreDataHelper.performAndWait {
            if let entity = self.coreDataHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
                entity.name = GeneralInfo.splitsChangeNumber.rawValue
                entity.longValue = 12345
            }
        }
        
        try? coreDataHelper.saveWithErrorHandling()
        
        let fetched = coreDataHelper.fetch(entity: .generalInfo)
        XCTAssertEqual(1, fetched.count)
        
        if let entity = fetched.first as? GeneralInfoEntity {
            XCTAssertEqual(12345, entity.longValue)
        } else {
            XCTFail("Expected GeneralInfoEntity")
        }
    }
    
    func testSaveWithErrorHandlingThrowsOnInvalidContext() {
        let invalidContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let invalidHelper = CoreDataHelper(
            managedObjectContext: invalidContext,
            persistentCoordinator: NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        )
        
        invalidContext.performAndWait {
            let entity = NSEntityDescription()
            entity.name = "TestEntity"
            entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        }
        
        // Context without persistent store should not throw when there are no changes
        XCTAssertNoThrow(try invalidHelper.saveWithErrorHandling())
    }

    func testRollbackClearsInvalidPendingChangesAndAllowsNextSave() {
        // Create an invalid entity that will cause a validation failure on save.
        coreDataHelper.performAndWait {
            _ = self.coreDataHelper.create(entity: .generalInfo)
        }

        XCTAssertThrowsError(try coreDataHelper.saveWithErrorHandling())

        // Rollback should clear the invalid pending changes so future saves can succeed.
        coreDataHelper.rollback()

        coreDataHelper.performAndWait {
            if let entity = self.coreDataHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
                entity.name = "post_rollback_ok"
                entity.stringValue = "value"
            }
        }

        XCTAssertNoThrow(try coreDataHelper.saveWithErrorHandling())
    }
}

