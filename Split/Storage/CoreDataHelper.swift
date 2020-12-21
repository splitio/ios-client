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
    case split = "Split"
    case mySegment = "MySegment"
    case generalInfo = "GeneralInfo"
}

class CoreDataHelper {
    let managedObjectContext: NSManagedObjectContext
    let persistentCoordinator: NSPersistentStoreCoordinator

    init(managedObjectContext: NSManagedObjectContext,
         persistentCoordinator: NSPersistentStoreCoordinator) {
        self.managedObjectContext = managedObjectContext
        self.persistentCoordinator = persistentCoordinator
    }

    func create(entity: CoreDataEntity) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entity.rawValue,
                                                   into: managedObjectContext)
    }

    func delete(entity: CoreDataEntity, by field: String, values: [String]) {
        delete(entity: entity, predicate: NSPredicate(format: "\(field) IN %@", values))
    }

    func save() {
        do {
            try managedObjectContext.save()
        } catch {
            Logger.e("Error while saving cache context: \(error.localizedDescription)")
        }
    }

    func generateId() -> String {
        return UUID().uuidString
    }

    func fetch(entity: CoreDataEntity, where predicate: NSPredicate? = nil, rowLimit: Int? = nil) -> [Any] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.rawValue)
        if let rowLimit = rowLimit {
            fetchRequest.fetchLimit = rowLimit
        }
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        do {
            return try managedObjectContext.fetch(fetchRequest)
        } catch {
            Logger.e("Error while loading \(entity.rawValue) objects from storage: \(error.localizedDescription)")
            return []
        }
    }

    func deleteAll(entity: CoreDataEntity) {
        delete(entity: entity)
    }

    private func delete(entity: CoreDataEntity, predicate: NSPredicate? = nil) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity.rawValue)
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentCoordinator.execute(deleteRequest, with: managedObjectContext)
        } catch {
            Logger.e("Error while deleting \(entity.rawValue) entities from storage: \(error.localizedDescription)")
        }
    }
}
