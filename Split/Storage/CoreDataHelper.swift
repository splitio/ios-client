//
//  CoreDataHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
import CoreData
import Logging

enum CoreDataEntity: String {
    case event = "Event"
    case impression = "Impression"
    case impressionsCount = "ImpressionsCount"
    case split = "Split"
    case mySegment = "MySegment"
    case myLargeSegment = "MyLargeSegment"
    case generalInfo = "GeneralInfo"
    case attribute = "Attribute"
    case uniqueKey = "UniqueKey"
    case hashedImpression = "HashedImpression"
    case ruleBasedSegment = "RuleBasedSegment"
}

class CoreDataHelper: @unchecked Sendable {
    typealias Operation = () -> Void
    private let managedObjectContext: NSManagedObjectContext
    private let persistentCoordinator: NSPersistentStoreCoordinator

    init(managedObjectContext: NSManagedObjectContext,
         persistentCoordinator: NSPersistentStoreCoordinator) {
        self.managedObjectContext = managedObjectContext
        self.persistentCoordinator = persistentCoordinator
    }

    func create(entity: CoreDataEntity) -> NSManagedObject {
        #if swift(>=6.0)
        nonisolated(unsafe) var obj: NSManagedObject!
        #else
        var obj: NSManagedObject!
        #endif

        managedObjectContext.performAndWait {
            obj = NSEntityDescription.insertNewObject(forEntityName: entity.rawValue,
                                                      into: self.managedObjectContext)
        }
        return obj
    }

    func delete(entity: CoreDataEntity, by field: String, values: [String]) {
        delete(entity: entity, predicate: NSPredicate(format: "\(field) IN %@", values))
    }

    // Explicitly using Int64 to ensure a 64-bit integer on all platforms.
    // Using Int without specifying a size defaults to Int32 on 32-bit platforms and Int64 on 64-bit platforms.
    func delete(entity: CoreDataEntity, by field: String, values: [Int64]) {
        delete(entity: entity, predicate: NSPredicate(format: "\(field) IN %@", values))
    }

    func save() {
        managedObjectContext.performAndWait {
            do {
                if self.managedObjectContext.hasChanges {
                    try self.managedObjectContext.save()
                }
            } catch {
                Logger.e("Error while saving cache context: \(error.localizedDescription)")
            }
        }
    }

    /// Save with error handling. Throws errors to caller
    /// Used for transactional operations that need to handle persistence failures
    func saveWithErrorHandling() throws {
        var thrownError: Error?
        managedObjectContext.performAndWait {
            do {
                if self.managedObjectContext.hasChanges {
                    try self.managedObjectContext.save()
                }
            } catch {
                thrownError = error
            }
        }
        if let error = thrownError {
            throw error
        }
    }

    func generateId() -> String {
        return UUID().uuidString
    }

    func fetch(entity: CoreDataEntity, where predicate: NSPredicate? = nil, rowLimit: Int? = nil) -> [Any] {
        #if swift(>=6.0)
        nonisolated(unsafe) var entities = [Any]()
        #else
        var entities = [Any]()
        #endif
        managedObjectContext.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.rawValue)
            if let rowLimit = rowLimit {
                fetchRequest.fetchLimit = rowLimit
            }
            if let predicate = predicate {
                fetchRequest.predicate = predicate
            }

            do {
                entities = try self.managedObjectContext.fetch(fetchRequest)
            } catch {
                Logger.e("Error while loading \(entity.rawValue) objects from storage: \(error.localizedDescription)")
            }
        }
        return entities
    }

    func deleteAll(entity: CoreDataEntity) {
        delete(entity: entity)
    }

    func perform(_ operation: @escaping Operation) {
        managedObjectContext.perform {
            operation()
        }
    }

    func performAndWait(_ operation: Operation) {
        managedObjectContext.performAndWait {
            operation()
        }
    }

    /// Roll back any unsaved changes in the managed object context.
    /// Useful after a failed save(), to prevent the context from keeping invalid pending changes.
    func rollback() {
        managedObjectContext.performAndWait {
            self.managedObjectContext.rollback()
        }
    }

    private func delete(entity: CoreDataEntity, predicate: NSPredicate? = nil) {

        managedObjectContext.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.rawValue)
            if let predicate = predicate {
                fetchRequest.predicate = predicate
            }
            do {
                var entities = try self.managedObjectContext.fetch(fetchRequest)
                let count = entities.count
                for _ in 0..<count {
                    if let entity = entities[0] as? NSManagedObject {
                        entities.remove(at: 0)
                        self.managedObjectContext.delete(entity)
                    }
                }
            } catch {
                Logger.e("Error while deleting \(entity.rawValue) entities from storage: \(error.localizedDescription)")
            }
        }
    }
}
