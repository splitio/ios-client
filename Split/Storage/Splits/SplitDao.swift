//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol SplitDao {
    func insertOrUpdate(_ splits: [Split])
    func getAll() -> [Split]
    func delete(_ splits: [String])
    func deleteAll()
}

class CoreDataSplitDao: SplitDao {
    let coreDataHelper: CoreDataHelper

    init(coreDataHelper: CoreDataHelper) {
        self.coreDataHelper = coreDataHelper
    }

    func insertOrUpdate(_ splits: [Split]) {
        for split in splits {
            if let splitName = split.name,
               let obj = getBy(name: splitName) ?? coreDataHelper.create(entity: .split) as? SplitEntity {
                do {
                    obj.name = splitName
                    obj.body = try Json.encodeToJson(split)
                    obj.updatedAt = Date().unixTimestamp()
                    coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting split in storage: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getAll() -> [Split] {
        return coreDataHelper.fetch(entity: .split)
            .compactMap { return $0 as? SplitEntity }
            .compactMap { return try? self.mapEntityToModel($0) }
    }
    
    func delete(_ splits: [String]) {
        coreDataHelper.delete(entity: .split, by: "name", values: splits)
    }
    
    func deleteAll() {
        coreDataHelper.deleteAll(entity: .split)
    }
    
    private func getBy(name: String) -> SplitEntity? {
        let predicate = NSPredicate(format: "name == %@", name)
        let entities = coreDataHelper.fetch(entity: .split,
                                            where: predicate).compactMap { return $0 as? SplitEntity }
        return entities.count > 0 ? entities[0] : nil
    }
    
    private func mapEntityToModel(_ entity: SplitEntity) throws -> Split {
        let model = try Json.encodeFrom(json: entity.body, to: Split.self)
        model.storageId = entity.storageId
        return model
    }
}
