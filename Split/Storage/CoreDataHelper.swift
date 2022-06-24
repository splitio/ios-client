//
//  CoreDataHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//
import CoreData

enum CoreDataEntity: String {
    case event = "Event"
    case impression = "Impression"
    case impressionsCount = "ImpressionsCount"
    case split = "Split"
    case mySegment = "MySegment"
    case generalInfo = "GeneralInfo"
    case attribute = "Attribute"
    case uniqueKey = "UniqueKey"
}

class CoreDataHelper {
    typealias Operation = () -> Void
    private let managedObjectContext: NSManagedObjectContext
    private let persistentCoordinator: NSPersistentStoreCoordinator

    init(managedObjectContext: NSManagedObjectContext,
         persistentCoordinator: NSPersistentStoreCoordinator) {
        self.managedObjectContext = managedObjectContext
        self.persistentCoordinator = persistentCoordinator
    }

    func create(entity: CoreDataEntity) -> NSManagedObject {
        var obj: NSManagedObject!

        managedObjectContext.performAndWait {
            obj = NSEntityDescription.insertNewObject(forEntityName: entity.rawValue,
                                                      into: self.managedObjectContext)
        }
        return obj
    }

    func delete(entity: CoreDataEntity, by field: String, values: [String]) {
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

    func generateId() -> String {
        return UUID().uuidString
    }

    func fetch(entity: CoreDataEntity, where predicate: NSPredicate? = nil, rowLimit: Int? = nil) -> [Any] {
        var entities = [Any]()
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
