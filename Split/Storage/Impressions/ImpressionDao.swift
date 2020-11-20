//
//  ImpressionDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol ImpressionDao {
    func insert(_ impression: Impression)
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [Impression]
    func update(ids: [String], newStatus: Int32)
    func delete(_ impressions: [Impression])
}

class CoreDataImpressionDao: ImpressionDao {

    let coreDataHelper: CoreDataHelper

    init(coreDataHelper: CoreDataHelper) {
        self.coreDataHelper = coreDataHelper
    }

    func insert(_ impression: Impression) {
        if let obj = coreDataHelper.create(entity: .impression) as? ImpressionEntity {
            do {
                obj.storageId = coreDataHelper.generateId()
                obj.body = try Json.encodeToJson(impression)
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting impressions in storage: \(error.localizedDescription)")
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [Impression] {
        var result = [Impression]()
        let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
        let entities = coreDataHelper.fetch(entity: .impression,
                                            where: predicate,
                                            rowLimit: maxRows).compactMap { return $0 as? ImpressionEntity }

        entities.forEach { entity in
            if let model = try? mapEntityToModel(entity) {
                result.append(model)
            }
        }

        return result
    }

    func update(ids: [String], newStatus: Int32) {
        let predicate = NSPredicate(format: "storageId IN %@", ids)
        let entities = coreDataHelper.fetch(entity: .impression,
                                            where: predicate).compactMap { return $0 as? ImpressionEntity }
        for entity in entities {
            entity.status = newStatus
        }
        coreDataHelper.save()
    }

    func delete(_ impressions: [Impression]) {
        coreDataHelper.delete(entity: .impression, by: "storageId", values: impressions.map { $0.storageId ?? "" })
    }

    func mapEntityToModel(_ entity: ImpressionEntity) throws -> Impression {
        let model = try Json.encodeFrom(json: entity.body, to: Impression.self)
        model.storageId = entity.storageId
        return model
    }
}
