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
    func insert(_ impression: KeyImpression)
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [KeyImpression]
    func update(ids: [String], newStatus: Int32)
    func delete(_ impressions: [KeyImpression])
}

class CoreDataImpressionDao: BaseCoreDataDao, ImpressionDao {

    let json = JsonWrapper()

    func insert(_ impression: KeyImpression) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let obj = self.coreDataHelper.create(entity: .impression) as? ImpressionEntity {
                do {
                    guard let testName = impression.featureName else {
                        // This should never happen
                        Logger.d("Impression without test name descarted")
                        return
                    }
                    obj.storageId = self.coreDataHelper.generateId()
                    obj.testName = testName
                    obj.body = try self.json.encodeToJson(impression)
                    obj.createdAt = Date().unixTimestamp()
                    obj.status = StorageRecordStatus.active
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting impressions in storage: \(error.localizedDescription)")
                }
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [KeyImpression] {
        var result = [KeyImpression]()
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

    func delete(_ impressions: [KeyImpression]) {
        if impressions.count == 0 {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .impression, by: "storageId",
                                       values: impressions.map { $0.storageId ?? "" })
        }
    }

    func mapEntityToModel(_ entity: ImpressionEntity) throws -> KeyImpression {
        do {
            var model = try Json.encodeFrom(json: entity.body, to: KeyImpression.self)
            model.storageId = entity.storageId
            model.featureName = entity.testName
            return model
        } catch {
            // if an error occurrs try with deprecated property parsing
            var model = try Json.encodeFrom(json: entity.body, to: DeprecatedImpression.self)
            model.storageId = entity.storageId
            model.featureName = entity.testName
            return model.toKeyImpression()
        }
    }
}
