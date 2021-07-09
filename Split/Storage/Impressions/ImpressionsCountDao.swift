//
//  ImpressionsCountDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 29-Jun-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import CoreData

protocol ImpressionsCountDao {
    func insert(_ count: ImpressionsCountPerFeature)
    func insert(_ counts: [ImpressionsCountPerFeature])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [ImpressionsCountPerFeature]
    func update(ids: [String], newStatus: Int32)
    func delete(_ counts: [ImpressionsCountPerFeature])
}

class CoreDataImpressionsCountDao: BaseCoreDataDao, ImpressionsCountDao {

    let json = JsonWrapper()

    func insert(_ count: ImpressionsCountPerFeature) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let obj = self.coreDataHelper.create(entity: .impressionsCount) as? ImpressionsCountEntity {
                do {
                    obj.storageId = self.coreDataHelper.generateId()
                    obj.body = try self.json.encodeToJson(count)
                    obj.createdAt = Date().unixTimestamp()
                    obj.status = StorageRecordStatus.active
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting impressions " +
                                "counts in storage: \(error.localizedDescription)")
                }
            }
        }
    }

    func insert(_ counts: [ImpressionsCountPerFeature]) {
        if counts.count == 0 {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            do {
                for count in counts {
                    if let obj = self.coreDataHelper.create(entity: .impressionsCount) as? ImpressionsCountEntity {
                        obj.storageId = self.coreDataHelper.generateId()
                        obj.body = try self.json.encodeToJson(count)
                        obj.createdAt = Date().unixTimestamp()
                        obj.status = StorageRecordStatus.active
                    }
                }
                self.coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting impressions " +
                            "counts in storage: \(error.localizedDescription)")
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [ImpressionsCountPerFeature] {
        var result = [ImpressionsCountPerFeature]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(entity: .impressionsCount,
                                                where: predicate,
                                                rowLimit: maxRows).compactMap { return $0 as? ImpressionsCountEntity }

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
            let entities =
                self.coreDataHelper.fetch(entity: .impressionsCount,
                                          where: predicate).compactMap { return $0 as? ImpressionsCountEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ counts: [ImpressionsCountPerFeature]) {
        if counts.count == 0 {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .impressionsCount, by: "storageId",
                                       values: counts.map { $0.storageId ?? "" })
        }
    }

    func mapEntityToModel(_ entity: ImpressionsCountEntity) throws -> ImpressionsCountPerFeature {
        var model = try Json.encodeFrom(json: entity.body, to: ImpressionsCountPerFeature.self)
        model.storageId = entity.storageId
        return model
    }
}
