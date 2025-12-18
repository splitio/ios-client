//
//  CoreDataHelperStub.swift
//  SplitTests
//

import Foundation
import CoreData
@testable import Split

class CoreDataHelperStub: CoreDataHelper {
    
    var shouldFailOnSave = false
    var saveError: Error = NSError(domain: "TestCoreData", code: 500, userInfo: [NSLocalizedDescriptionKey: "Simulated save failure"])
    var rollbackCalled = false
    
    init() {
        let model = NSManagedObjectModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        super.init(managedObjectContext: context, persistentCoordinator: coordinator)
    }
    
    override func performAndWait(_ operation: () -> Void) {
        operation()
    }
    
    override func perform(_ operation: @escaping () -> Void) {
        operation()
    }
    
    override func save() {
        // No-op for stubs
    }
    
    override func saveWithErrorHandling() throws {
        if shouldFailOnSave {
            throw saveError
        }
        // Success
    }

    override func rollback() {
        rollbackCalled = true
    }
}

