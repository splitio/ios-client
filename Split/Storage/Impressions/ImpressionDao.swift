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

class CoreDataImpressionDao: BaseCoreDataDao, ImpressionDao {

    func insert(_ impression: Impression) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let obj = self.coreDataHelper.create(entity: .impression) as? ImpressionEntity {
                do {
                    guard let testName = impression.feature else {
                        // This should never happen
                        Logger.d("Impression without test name descarted")
                        return
                    }
                    obj.storageId = self.coreDataHelper.generateId()
                    obj.testName = testName
                    obj.body = try Json.encodeToJson(impression)
                    obj.createdAt = Date().unixTimestamp()
                    obj.status = StorageRecordStatus.active
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting impressions in storage: \(error.localizedDescription)")
                }
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [Impression] {
        var result = [Impression]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(entity: .impression,
                                                where: predicate,
                                                rowLimit: maxRows).compactMap { return $0 as? ImpressionEntity }

            entities.forEach { entity in
                if let model = try? self.mapEntityToModel(entity) {
                    result.append(model)
                }
            }
        }
        return result
    }

    func update(ids: [String], newStatus: Int32) {
        if ids.count == 0 {
            return
        }
     
        let predicate = NSPredicate(format: "storageId IN %@", ids)

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            let entities = self.coreDataHelper.fetch(entity: .impression,
                                                     where: predicate).compactMap { return $0 as? ImpressionEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ impressions: [Impression]) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .impression, by: "storageId",
                                       values: impressions.map { $0.storageId ?? "" })
        }
    }

    func mapEntityToModel(_ entity: ImpressionEntity) throws -> Impression {
        let model = try Json.encodeFrom(json: entity.body, to: Impression.self)
        model.storageId = entity.storageId
        model.feature = entity.testName
        return model
    }
}
